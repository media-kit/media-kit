// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'package:media_kit/ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as libmpv_bindings;
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
  /// {@macro initializer_isolate}
  factory InitializerIsolate() {
    _instance ??= InitializerIsolate._(NativeLibrary.path);
    return _instance!;
  }

  /// {@macro initializer_isolate}
  InitializerIsolate._(this.libmpv);

  /// Singleton instance.
  static InitializerIsolate? _instance;

  /// Resolved libmpv dynamic library.
  final String libmpv;

  /// Creates [Pointer<mpv_handle>].
  Future<Pointer<libmpv_bindings.mpv_handle>> create(
    Future<void> Function(Pointer<libmpv_bindings.mpv_event>) callback, {
    Map<String, String> options = const {},
  }) async {
    final completer = Completer<void>();
    final receiver = ReceivePort();
    late SendPort port;
    late Pointer<libmpv_bindings.mpv_handle> handle;
    final Isolate isolate = await Isolate.spawn(_mainloop, receiver.sendPort);
    receiver.listen((message) async {
      if (!completer.isCompleted && message is SendPort) {
        port = message
          ..send(options)
          ..send(libmpv);
      } else if (!completer.isCompleted && message is int) {
        handle = Pointer.fromAddress(message);
        // Intialiation complete.
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      // Forward events to the supplied callback.
      else if (message != null) {
        final Pointer<libmpv_bindings.mpv_event> event =
            Pointer.fromAddress(message as int);
        try {
          await callback(event);
        } on Object catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
        port.send(true);
      } else {
        receiver.close();
      }
    });
    // Awaiting the retrieval of [Pointer<mpv_handle>].
    await completer.future;

    // Save the references.
    _ports[handle.address] = port;
    _isolates[handle.address] = isolate;

    return handle;
  }

  /// Disposes [Pointer<mpv_handle>].
  void dispose(
      libmpv_bindings.MPV mpv, Pointer<libmpv_bindings.mpv_handle> handle) {
    final SendPort? port = _ports[handle.address];
    final Isolate? isolate = _isolates[handle.address];
    if (port != null && isolate != null) {
      port.send(null);

      _ports.remove(handle.address);
      _isolates.remove(handle.address);

      mpv.mpv_wakeup(handle);

      Future.delayed(const Duration(seconds: 2), () {
        isolate.kill(priority: Isolate.immediate);
      });
    }
  }

  static Future<void> _mainloop(SendPort port) async {
    var completer = Completer<void>();

    final receiver = ReceivePort();
    port.send(receiver.sendPort);

    late Map<String, String> options;
    late libmpv_bindings.MPV mpv;

    var disposed = false;

    Pointer<libmpv_bindings.mpv_handle>? handle;

    receiver.listen((message) {
      if (message is Map<String, String>) {
        options = message;
      } else if (message is String) {
        mpv = libmpv_bindings.MPV(DynamicLibrary.open(message));
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (message is bool) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else if (message == null) {
        if (handle != null) {
          disposed = true;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      }
    });

    await completer.future;

    handle ??= mpv.mpv_create();

    for (final MapEntry<String, String> entry in options.entries) {
      final Pointer<Utf8> name = entry.key.toNativeUtf8();
      final Pointer<Utf8> value = entry.value.toNativeUtf8();
      mpv.mpv_set_option_string(handle, name.cast(), value.cast());
      calloc
        ..free(name)
        ..free(value);
    }

    mpv.mpv_initialize(handle);
    port.send(handle.address);

    while (!disposed) {
      completer = Completer();
      final Pointer<libmpv_bindings.mpv_event> event =
          mpv.mpv_wait_event(handle, kReleaseMode ? -1 : 0.1);
      if (disposed) {
        break;
      }
      if (event.ref.event_id != libmpv_bindings.mpv_event_id.MPV_EVENT_NONE) {
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
}
