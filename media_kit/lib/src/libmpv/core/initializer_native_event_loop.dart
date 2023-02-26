/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names, unused_local_variable, camel_case_types

import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:collection';

import 'package:media_kit/generated/libmpv/bindings.dart';

/// Name of the shared library used for platform specific threaded event handling.
///
/// See:
/// https://github.com/alexmercerind/media_kit/issues/40
/// https://github.com/alexmercerind/media_kit/pull/46
/// https://github.com/dart-lang/sdk/issues/51254
/// https://github.com/dart-lang/sdk/issues/51261
const kNativeEventLoopDynamicLibrary = 'media_kit_native_event_loop';

// Type definitions for native functions in the shared library.

// C/C++:

typedef Dart_InitializeApiDLCXX = Void Function(Pointer<Void> data);
typedef MediaKitEventLoopHandlerRegisterCXX = Void Function(
  Int64 handle,
  Pointer<Void> callback,
  Int64 port,
);

// Dart:

typedef MediaKitEventLoopHandlerNotifyCXX = Void Function(Int64 handle);
typedef Dart_InitializeApiDLDart = void Function(Pointer<Void> data);
typedef MediaKitEventLoopHandlerRegisterDart = void Function(
  int handle,
  Pointer<Void> callback,
  int port,
);
typedef MediaKitEventLoopHandlerNotifyDart = void Function(int handle);

// Resolved native functions from the shared library.
Dart_InitializeApiDLDart? Dart_InitializeApiDL;
MediaKitEventLoopHandlerRegisterDart? MediaKitEventLoopHandlerRegister;
MediaKitEventLoopHandlerNotifyDart? MediaKitEventLoopHandlerNotify;

// Registered [callback]s to receive [mpv_event](s) from the native event loop.
final callbacks = HashMap<int, Future<void> Function(Pointer<mpv_event>)>();

/// [ReceivePort] used to listen for `mpv_event`(s) from the native event loop.
/// A single [ReceivePort] is used for multiple instances.
final receiver = ReceivePort()
  ..listen(
    (dynamic message) async {
      try {
        final handle = message[0] as int;
        final event = Pointer<mpv_event>.fromAddress(message[1]);
        if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
          callbacks.remove(handle);
        } else {
          // Notify public event handler.
          await callbacks[handle]?.call(event);
        }
      } catch (exception, stacktrace) {
        print(exception);
        print(stacktrace);
      }
      // Notify native event loop that event has been handled & it is safe to move onto next `mpv_wait_event`.
      MediaKitEventLoopHandlerNotify?.call(message[0]);
    },
  );

/// Creates & returns initialized [Pointer] to [mpv_handle] whose event loop is running on native thread.
///
/// Pass [path] to libmpv dynamic library & [callback] to receive event callbacks as [Pointer] to [mpv_event].
Future<Pointer<mpv_handle>> create(
  String path,
  Future<void> Function(Pointer<mpv_event> event)? callback,
) async {
  // Load native functions from the shared library on first call.
  if (Dart_InitializeApiDL == null &&
      MediaKitEventLoopHandlerRegister == null &&
      MediaKitEventLoopHandlerNotify == null) {
    final dylib = () {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open(
          '$kNativeEventLoopDynamicLibrary.framework/$kNativeEventLoopDynamicLibrary',
        );
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('lib$kNativeEventLoopDynamicLibrary.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('$kNativeEventLoopDynamicLibrary.dll');
      }
    }();
    if (dylib != null) {
      // Load native functions from the dynamic library.
      Dart_InitializeApiDL = dylib.lookupFunction<Dart_InitializeApiDLCXX,
          Dart_InitializeApiDLDart>('Dart_InitializeApiDL');
      MediaKitEventLoopHandlerRegister = dylib.lookupFunction<
          MediaKitEventLoopHandlerRegisterCXX,
          MediaKitEventLoopHandlerRegisterDart>(
        'MediaKitEventLoopHandlerRegister',
      );
      MediaKitEventLoopHandlerNotify = dylib.lookupFunction<
          MediaKitEventLoopHandlerNotifyCXX,
          MediaKitEventLoopHandlerNotifyDart>(
        'MediaKitEventLoopHandlerNotify',
      );

      // Initialize dart_api_dl.h.
      Dart_InitializeApiDL?.call(NativeApi.initializeApiDLData);
    }
  }
  // Native functions from the shared library should be resolved by now.
  // If not, throw an exception.
  // Primarily, this will happen when the shared library is not found i.e. package:media_kit_native_event_loop is not installed.
  if (Dart_InitializeApiDL == null ||
      MediaKitEventLoopHandlerRegister == null ||
      MediaKitEventLoopHandlerNotify == null) {
    throw Exception(
      'package:media_kit/src/core/initializer_event_loop.dart: Unable to find native event loop shared library.',
    );
  }

  // Create [mpv_handle] & initialize it.
  final mpv = MPV(DynamicLibrary.open(path));
  final handle = mpv.mpv_create();
  mpv.mpv_initialize(handle);

  // Only register for event callbacks if [callback] is not null.
  if (callback != null) {
    // Save [callback] to invoke it inside [ReceivePort] listener.
    callbacks[handle.address] = callback;

    // Register event callback.
    MediaKitEventLoopHandlerRegister?.call(
      handle.address,
      NativeApi.postCObject.cast(),
      receiver.sendPort.nativePort,
    );
  }

  return handle;
}
