/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

/// InitializerIsolate
/// ------------------
///
/// Creates & returns initialized [Pointer] to [mpv_handle] whose event loop is running on separate isolate.
abstract class InitializerIsolate {
  /// Creates & returns initialized [Pointer] to [mpv_handle] whose event loop is running on separate isolate.
  static Future<Pointer<mpv_handle>> create(
    String path,
    Future<void> Function(Pointer<mpv_event> event)? callback,
    Map<String, String> options,
  ) async {
    if (callback == null) {
      // No requirement for separate isolate.
      final mpv = MPV(DynamicLibrary.open(path));
      // Creating [mpv_handle].
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

      // Initializing [mpv_handle].
      mpv.mpv_initialize(handle);
      return handle;
    } else {
      // Used to wait for retrieval of [Pointer] to [mpv_handle] from the running isolate.
      final completer = Completer();
      // Used to receive events from the separate isolate.
      final receiver = ReceivePort();
      // Late initialized [mpv_handle] & [SendPort] of the [ReceievePort] inside the separate isolate.
      late Pointer<mpv_handle> handle;
      late SendPort port;
      // Run mainloop in the separate isolate.
      await Isolate.spawn(
        _mainloop,
        receiver.sendPort,
      );
      receiver.listen(
        (message) async {
          // Receiving [SendPort] of the [ReceivePort] inside the separate isolate to:
          // 1. Send the custom defined options.
          // 2. Send the path to [DynamicLibrary].
          if (!completer.isCompleted && message is SendPort) {
            port = message;
            port.send(options);
            port.send(path);
          }
          // Receiving [Pointer] to [mpv_handle] created by separate isolate.
          else if (!completer.isCompleted && message is int) {
            handle = Pointer.fromAddress(message);
            completer.complete();
          }
          // Receiving event callbacks.
          else {
            Pointer<mpv_event> event = Pointer.fromAddress(message);
            try {
              await callback(event);
            } catch (exception, stacktrace) {
              print(exception.toString());
              print(stacktrace.toString());
            }
            port.send(true);
          }
        },
      );
      // Awaiting the retrieval of [Pointer] to [mpv_handle].
      await completer.future;
      return handle;
    }
  }

  /// Detect if app running in release mode.
  static const _isReleaseMode = bool.fromEnvironment('dart.vm.product');

  /// Runs on separate isolate.
  /// Calls [MPV.mpv_create] & [MPV.mpv_initialize] to create a new [mpv_handle].
  /// Uses [MPV.mpv_wait_event] to wait for the next event & notifies through the passed [SendPort] as the argument.
  ///
  /// First value sent through the [SendPort] is [SendPort] of the internal [ReceivePort].
  /// Second value sent through the [SendPort] is raw address of the [Pointer] to [mpv_handle] created by the isolate.
  /// Subsequent sent values are [Pointer] to [mpv_event].
  @pragma('vm:entry-point')
  static void _mainloop(SendPort port) async {
    // [Completer] used to ensure that the last [mpv_event] is NOT reset to [mpv_event_id.MPV_EVENT_NONE] after waiting using [MPV.mpv_wait_event] again in the continuously running while loop.
    var completer = Completer();

    // Used to recieve the confirmation messages from the main thread about successful receive of the sent event through [SendPort].
    // Upon confirmation, the [Completer] is completed & we jump to next iteration of the while loop waiting with [MPV.mpv_wait_event].
    final receiver = ReceivePort();

    // Send the [SendPort] of internal [ReceivePort].
    port.send(receiver.sendPort);

    // Received data from the [SendPort] for initialization.
    late Map<String, String> options;
    late MPV mpv;

    Pointer<mpv_handle>? handle;

    // First received value is [Map<String, String>] of options.
    // Second received value is [String] of path to [DynamicLibrary].
    receiver.listen(
      (message) {
        if (message is Map<String, String>) {
          options = message;
        } else if (message is String) {
          mpv = MPV(DynamicLibrary.open(message));
          completer.complete();
        } else if (message is bool) {
          completer.complete();
        } else if (message == null) {
          if (handle != null) {
            mpv.mpv_wakeup(handle);
          }
        }
      },
    );

    // Wait for the [Completer] to complete.
    await completer.future;

    // Creating [mpv_handle].
    handle ??= mpv.mpv_create();

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

    // Initializing [mpv_handle].
    mpv.mpv_initialize(handle);

    // Sending the address of the created [mpv_handle] & the [SendPort] of the [receivePort].
    // Raw address is sent as [int] since we cannot transfer objects through Native Ports, only primatives.
    port.send(handle.address);

    // Lookup for events & send to main thread through [SendPort].
    // Ensuring the successful sending of the last event before moving to next [MPV.mpv_wait_event].
    while (true) {
      completer = Completer();
      final event = mpv.mpv_wait_event(handle, _isReleaseMode ? -1 : 0.1);
      // Sending raw address of [mpv_event].
      port.send(event.address);
      // Ensuring that the last [mpv_event] (which is at the same address) is NOT reset to [mpv_event_id.MPV_EVENT_NONE] after next [MPV.mpv_wait_event] in the loop.
      await completer.future;
      if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
        break;
      }
    }
  }
}
