/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:collection';

import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as generated;
import 'package:media_kit/src/player/native/core/native_library.dart';
import 'package:media_kit/src/values.dart';

/// {@template initializer_isolate}
///
/// InitializerIsolate
/// ------------------
/// Initializes [Pointer<mpv_handle>] & notifies about events through the supplied callback.
///
/// {@endtemplate}
class InitializerIsolate {
  /// Singleton instance.
  static InitializerIsolate? _instance;

  /// {@macro initializer_isolate}
  InitializerIsolate._(this.libmpv);

  /// {@macro initializer_isolate}
  factory InitializerIsolate() {
    _instance ??= InitializerIsolate._(NativeLibrary.path);
    return _instance!;
  }

  /// Resolved libmpv dynamic library.
  final String libmpv;

  /// Creates [Pointer<mpv_handle>].
  Future<Pointer<generated.mpv_handle>> create(
    Future<void> Function(Pointer<generated.mpv_event>) callback, {
    Map<String, String> options = const {},
  }) async {
    final completer = Completer<void>();
    final receiver = ReceivePort();
    final failurePort = ReceivePort();
    late SendPort port;
    late Pointer<generated.mpv_handle> handle;
    Isolate? isolate;
    try {
      failurePort.listen((message) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(
              'libmpv isolate terminated before initialization: $message',
            ),
          );
        }
      });
      isolate = await Isolate.spawn(
        _mainloop,
        receiver.sendPort,
        onError: failurePort.sendPort,
        onExit: failurePort.sendPort,
      );
      receiver.listen(
        (message) async {
          if (!completer.isCompleted && message is SendPort) {
            port = message;
            port.send(options);
            port.send(libmpv);
          } else if (!completer.isCompleted && message is int) {
            handle = Pointer.fromAddress(message);
            // Initialization complete.
            completer.complete();
          }
          // Forward events to the supplied callback.
          else if (message is int) {
            Pointer<generated.mpv_event> event = Pointer.fromAddress(message);
            try {
              await callback(event);
            } catch (exception, stacktrace) {
              print(exception.toString());
              print(stacktrace.toString());
            }
            port.send(true);
          } else {
            receiver.close();
          }
        },
      );
      // Awaiting the retrieval of [Pointer<mpv_handle>].
      await completer.future;

      isolate.removeErrorListener(failurePort.sendPort);
      isolate.removeOnExitListener(failurePort.sendPort);
      failurePort.close();

      // Save the references.
      _ports[handle.address] = port;
      _isolates[handle.address] = isolate;
      _receivers[handle.address] = receiver;

      return handle;
    } catch (_) {
      isolate?.removeErrorListener(failurePort.sendPort);
      isolate?.removeOnExitListener(failurePort.sendPort);
      failurePort.close();
      receiver.close();
      isolate?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  /// Disposes [Pointer<mpv_handle>].
  void dispose(generated.MPV mpv, Pointer<generated.mpv_handle> handle) {
    final port = _ports.remove(handle.address);
    final isolate = _isolates.remove(handle.address);
    final receiver = _receivers.remove(handle.address);
    if (port != null && isolate != null) {
      port.send(null);
      mpv.mpv_wakeup(handle);

      Future.delayed(const Duration(seconds: 2), () {
        isolate.kill(priority: Isolate.immediate);
        receiver?.close();
      });
    } else {
      receiver?.close();
    }
  }

  static void _mainloop(SendPort port) async {
    Completer completer = Completer();

    final receiver = ReceivePort();
    port.send(receiver.sendPort);

    late Map<String, String> options;
    late generated.MPV mpv;

    bool disposed = false;

    Pointer<generated.mpv_handle>? handle;

    receiver.listen(
      (message) {
        if (message is Map<String, String>) {
          options = message;
        } else if (message is String) {
          mpv = generated.MPV(DynamicLibrary.open(message));
          completer.complete();
        } else if (message is bool) {
          completer.complete();
        } else if (message == null) {
          if (handle != null) {
            disposed = true;
            completer.complete();
          }
        }
      },
    );

    await completer.future;

    try {
      handle ??= mpv.mpv_create();
      if (handle == nullptr) {
        throw StateError('mpv_create returned nullptr');
      }

      for (final entry in options.entries) {
        final name = entry.key.toNativeUtf8();
        Pointer<Utf8>? value;
        try {
          value = entry.value.toNativeUtf8();
          mpv.mpv_set_option_string(handle, name.cast(), value.cast());
        } finally {
          calloc.free(name);
          if (value != null) calloc.free(value);
        }
      }

      final initError = mpv.mpv_initialize(handle);
      if (initError < 0) {
        throw StateError('mpv_initialize failed with error code $initError');
      }
      port.send(handle.address);
    } catch (_) {
      if (handle != null && handle != nullptr) {
        mpv.mpv_terminate_destroy(handle);
      }
      receiver.close();
      rethrow;
    }

    while (!disposed) {
      completer = Completer();
      final event = mpv.mpv_wait_event(handle, kReleaseMode ? -1 : 0.1);
      if (disposed) {
        break;
      }
      if (event.ref.event_id != generated.mpv_event_id.MPV_EVENT_NONE) {
        port.send(event.address);
        await completer.future;
      } else {
        await Future.delayed(Duration.zero);
      }
    }

    port.send(null);
    receiver.close();
  }

  final _ports = HashMap<int, SendPort>();
  final _isolates = HashMap<int, Isolate>();
  final _receivers = HashMap<int, ReceivePort>();
}
