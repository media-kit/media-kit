/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:collection';

import 'package:media_kit/generated/libmpv/bindings.dart';

/// InitializerNativeEventLoop
/// --------------------------
///
/// Creates & returns initialized [Pointer] to [mpv_handle] whose event loop is running on native thread.
///
/// See:
/// * https://github.com/alexmercerind/media_kit/issues/40
/// * https://github.com/alexmercerind/media_kit/pull/46
/// * https://github.com/dart-lang/sdk/issues/51254
/// * https://github.com/dart-lang/sdk/issues/51261
///
abstract class InitializerNativeEventLoop {
  /// Initializes the |InitializerNativeEventLoop| class for usage.
  static void ensureInitialized() {
    try {
      final dylib = () {
        if (Platform.isMacOS || Platform.isIOS) {
          return DynamicLibrary.open(
            'media_kit_native_event_loop.framework/media_kit_native_event_loop',
          );
        }
        if (Platform.isAndroid || Platform.isLinux) {
          return DynamicLibrary.open('libmedia_kit_native_event_loop.so');
        }
        if (Platform.isWindows) {
          return DynamicLibrary.open('media_kit_native_event_loop.dll');
        }
      }()!;
      _initialize = dylib.lookupFunction<MediaKitEventLoopHandlerInitializeCXX,
          MediaKitEventLoopHandlerInitializeDart>(
        'MediaKitEventLoopHandlerInitialize',
      );
      _register = dylib.lookupFunction<MediaKitEventLoopHandlerRegisterCXX,
          MediaKitEventLoopHandlerRegisterDart>(
        'MediaKitEventLoopHandlerRegister',
      );
      _notify = dylib.lookupFunction<MediaKitEventLoopHandlerNotifyCXX,
          MediaKitEventLoopHandlerNotifyDart>(
        'MediaKitEventLoopHandlerNotify',
      );

      // Initialize the native event loop handler.
      _initialize?.call();
    } catch (exception) {
      print(
        'media_kit: WARNING: package:media_kit_native_event_loop not found.',
      );
    }
  }

  /// Creates & returns initialized [Pointer] to [mpv_handle] whose event loop is running on native thread.
  static Future<Pointer<mpv_handle>> create(
    String path,
    Future<void> Function(Pointer<mpv_event> event)? callback,
  ) async {
    // Native functions from the shared library should be resolved by now.
    // If not, throw an exception.
    // Primarily, this will happen when the shared library is not found i.e. package:media_kit_native_event_loop is not installed.
    if (_register == null || _notify == null) {
      throw Exception(
        'package:media_kit_native_event_loop shared library not loaded.',
      );
    }

    // Create [mpv_handle] & initialize it.
    final mpv = MPV(DynamicLibrary.open(path));

    final handle = mpv.mpv_create();
    mpv.mpv_initialize(handle);

    // Only register for event callbacks if [callback] is not null.
    if (callback != null) {
      // Save [callback] to invoke it inside [ReceivePort] listener.
      _callbacks[handle.address] = callback;
      // Register event callback.
      _register?.call(
        handle.address,
        NativeApi.postCObject.cast(),
        _receiver.sendPort.nativePort,
      );
    }

    return handle;
  }

  /// [ReceivePort] used to listen for `mpv_event`(s) from the native event loop.
  /// A single [ReceivePort] is used for multiple instances.
  static final _receiver = ReceivePort()
    ..listen(
      (dynamic message) async {
        try {
          final handle = message[0] as int;
          final event = Pointer<mpv_event>.fromAddress(message[1]);
          if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
            _callbacks.remove(handle);
          } else {
            // Notify public event handler.
            await _callbacks[handle]?.call(event);
          }
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
        // Notify native event loop that event has been handled & it is safe to move onto next `mpv_wait_event`.
        _notify?.call(message[0]);
      },
    );

  // Registered [callback]s to receive [mpv_event](s) from the native event loop.
  static final _callbacks =
      HashMap<int, Future<void> Function(Pointer<mpv_event>)>();

  // Resolved native functions from the shared library:

  static MediaKitEventLoopHandlerInitializeDart? _initialize;
  static MediaKitEventLoopHandlerRegisterDart? _register;
  static MediaKitEventLoopHandlerNotifyDart? _notify;
}

// Type definitions for native functions in the shared library.

// C/C++:

typedef MediaKitEventLoopHandlerInitializeCXX = Void Function();
typedef MediaKitEventLoopHandlerRegisterCXX = Void Function(
  Int64 handle,
  Pointer<Void> callback,
  Int64 port,
);
typedef MediaKitEventLoopHandlerNotifyCXX = Void Function(Int64 handle);

// Dart:

typedef MediaKitEventLoopHandlerInitializeDart = void Function();
typedef MediaKitEventLoopHandlerRegisterDart = void Function(
  int handle,
  Pointer<Void> callback,
  int port,
);
typedef MediaKitEventLoopHandlerNotifyDart = void Function(int handle);
