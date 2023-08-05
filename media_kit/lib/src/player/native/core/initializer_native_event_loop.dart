/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:collection';

import 'package:media_kit/ffi/ffi.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';
import 'package:media_kit/src/player/native/utils/isolates.dart';

/// InitializerNativeEventLoop
/// --------------------------
///
/// Creates & returns initialized [Pointer<mpv_handle>] whose event loop is running on native thread.
///
/// See:
/// * https://github.com/media-kit/media-kit/issues/40
/// * https://github.com/media-kit/media-kit/pull/46
/// * https://github.com/dart-lang/sdk/issues/51254
/// * https://github.com/dart-lang/sdk/issues/51261
///
abstract class InitializerNativeEventLoop {
  /// Initializes the |InitializerNativeEventLoop| class for usage.
  static void ensureInitialized() {
    try {
      final initialize = lib.lookupFunction<
          MediaKitEventLoopHandlerInitializeCXX,
          MediaKitEventLoopHandlerInitializeDart>(
        'MediaKitEventLoopHandlerInitialize',
      );
      initialize.call();
    } catch (_) {
      print(
        'media_kit: WARNING: package:media_kit_native_event_loop not found.',
      );
    }
  }

  /// Creates & returns initialized [Pointer<mpv_handle>] whose event loop is running on native thread.
  static Future<Pointer<mpv_handle>> create(
    String path,
    Future<void> Function(Pointer<mpv_event> event)? callback,
    Map<String, String> options,
  ) async {
    // Native functions from the shared library should be resolved by now. If not, throw an exception.
    // Primarily, this will happen when the shared library is not found i.e. package:media_kit_native_event_loop is not installed.
    try {
      lib;
    } catch (_) {
      throw Exception(
        'package:media_kit_native_event_loop shared library not loaded.',
      );
    }

    // Create [mpv_handle] & initialize it.
    final mpv = MPV(DynamicLibrary.open(path));

    final handle = mpv.mpv_create();

    // Set custom defined options before [mpv_initialize].
    for (final entry in options.entries) {
      final name = entry.key.toNativeUtf8();
      final value = entry.value.toNativeUtf8();
      mpv.mpv_set_option_string(
        handle,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }

    mpv.mpv_initialize(handle);

    // Only register for event callbacks if [callback] is not null.
    if (callback != null) {
      // Save [callback] to invoke it inside [ReceivePort] listener.
      _callbacks[handle.address] = callback;
      // Register event callback.
      await _register(
        handle.address,
        NativeApi.postCObject.cast(),
        _receiver.sendPort.nativePort,
      );
    }

    return handle;
  }

  /// Disposes the event loop of the [Pointer<mpv_handle>] created by [create].
  /// NOTE: [Pointer<mpv_handle>] itself is not disposed.
  static Future<void> dispose(Pointer<mpv_handle> handle) async {
    // Native functions from the shared library should be resolved by now. If not, throw an exception.
    // Primarily, this will happen when the shared library is not found i.e. package:media_kit_native_event_loop is not installed.
    try {
      lib;
    } catch (_) {
      throw Exception(
        'package:media_kit_native_event_loop shared library not loaded.',
      );
    }

    _callbacks.remove(handle.address);
    await _dispose.call(handle.address);
  }

  /// [ReceivePort] used to listen for `mpv_event`(s) from the native event loop.
  /// A single [ReceivePort] is used for multiple instances.
  static final _receiver = ReceivePort()
    ..listen(
      (dynamic message) async {
        try {
          final handle = message[0] as int;
          final event = Pointer<mpv_event>.fromAddress(message[1]);
          // Notify public event handler.
          await _callbacks[handle]?.call(event);
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
        // Notify native event loop that event has been handled & it is safe to move onto next `mpv_wait_event`.
        await _notify(message[0]);
      },
    );

  static Future<void> _register(int handle, Pointer<Void> callback, int port) {
    return compute(
      _registerIsolate,
      _RegisterData(
        handle,
        callback.address,
        port,
      ),
    );
  }

  static Future<void> _notify(int handle) {
    return compute(
      _notifyIsolate,
      _NotifyData(handle),
    );
  }

  static Future<void> _dispose(int handle) {
    return compute(
      _disposeIsolate,
      _DisposeData(handle),
    );
  }

  static void _registerIsolate(_RegisterData data) {
    final register = lib.lookupFunction<MediaKitEventLoopHandlerRegisterCXX,
        MediaKitEventLoopHandlerRegisterDart>(
      'MediaKitEventLoopHandlerRegister',
    );
    register.call(
      data.handle,
      Pointer.fromAddress(data.callback),
      data.port,
    );
  }

  static void _notifyIsolate(_NotifyData data) {
    final notify = lib.lookupFunction<MediaKitEventLoopHandlerNotifyCXX,
        MediaKitEventLoopHandlerNotifyDart>(
      'MediaKitEventLoopHandlerNotify',
    );
    notify.call(data.handle);
  }

  static void _disposeIsolate(_DisposeData data) {
    final dispose = lib.lookupFunction<MediaKitEventLoopHandlerDisposeCXX,
        MediaKitEventLoopHandlerDisposeDart>(
      'MediaKitEventLoopHandlerDispose',
    );
    dispose.call(data.handle);
  }

  // The resolved package:media_kit_native_event_loop shared library.
  static DynamicLibrary? _lib;
  static DynamicLibrary get lib {
    if (_lib != null) {
      return _lib!;
    }
    if (Platform.isMacOS || Platform.isIOS) {
      _lib = DynamicLibrary.open(
        'media_kit_native_event_loop.framework/media_kit_native_event_loop',
      );
    }
    if (Platform.isAndroid || Platform.isLinux) {
      _lib = DynamicLibrary.open('libmedia_kit_native_event_loop.so');
    }
    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('media_kit_native_event_loop.dll');
    }
    return _lib!;
  }

  // Registered [callback]s to receive [mpv_event](s) from the native event loop.
  static final _callbacks =
      HashMap<int, Future<void> Function(Pointer<mpv_event>)>();
}

// Type definitions for native functions in the shared library.

// C/C++:

typedef MediaKitEventLoopHandlerRegisterCXX = Void Function(
  Int64 handle,
  Pointer<Void> callback,
  Int64 port,
);
typedef MediaKitEventLoopHandlerNotifyCXX = Void Function(Int64 handle);
typedef MediaKitEventLoopHandlerDisposeCXX = Void Function(Int64 handle);
typedef MediaKitEventLoopHandlerInitializeCXX = Void Function();

// Dart:

typedef MediaKitEventLoopHandlerRegisterDart = void Function(
  int handle,
  Pointer<Void> callback,
  int port,
);
typedef MediaKitEventLoopHandlerNotifyDart = void Function(int handle);
typedef MediaKitEventLoopHandlerDisposeDart = void Function(int handle);
typedef MediaKitEventLoopHandlerInitializeDart = void Function();

// --------------------------------------------------

class _RegisterData {
  final int handle;
  final int callback;
  final int port;
  const _RegisterData(this.handle, this.callback, this.port);
}

class _NotifyData {
  final int handle;
  const _NotifyData(this.handle);
}

class _DisposeData {
  final int handle;
  const _DisposeData(this.handle);
}

// --------------------------------------------------
