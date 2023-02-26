import 'dart:ffi';

import 'package:media_kit/generated/libmpv/bindings.dart';

import 'initializer_isolate.dart' as initializer_isolate;
import 'initializer_native_event_loop.dart' as initializer_native_event_loop;

/// Creates & returns initialized [Pointer] to [mpv_handle].
/// Pass [path] to libmpv dynamic library & [callback] to receive event callbacks as [Pointer] to [mpv_event].
///
/// Platform specific threaded event loop is preferred over [Isolate] based event loop (automatic fallback).
/// See package:media_kit_native_event_loop for more details.
///
Future<Pointer<mpv_handle>> create(
  String path,
  Future<void> Function(Pointer<mpv_event> event) callback,
) async {
  try {
    return await initializer_native_event_loop.create(path, callback);
  } catch (exception, stacktrace) {
    print(exception);
    print(stacktrace);
    return await initializer_isolate.create(path, callback);
  }
}
