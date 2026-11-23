// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:isolate';

import 'package:media_kit/generated/libmpv/bindings.dart' as libmpv_bindings;
import 'package:media_kit/src/player/native/core/execmem_restriction.dart';
import 'package:media_kit/src/player/native/core/initializer_isolate.dart';
import 'package:media_kit/src/player/native/core/initializer_native_callable.dart';
import 'package:media_kit/src/values.dart';

/// {@template initializer}
///
/// Initializer
/// -----------
/// Initializes [Pointer<mpv_handle>] & notifies about events through the supplied callback.
///
/// {@endtemplate}
class Initializer {
  /// {@macro initializer}
  factory Initializer(libmpv_bindings.MPV mpv) {
    _instance ??= Initializer._(mpv);
    return _instance!;
  }

  /// {@macro initializer}
  Initializer._(this.mpv);

  /// Singleton instance.
  static Initializer? _instance;

  /// Generated libmpv C API bindings.
  final libmpv_bindings.MPV mpv;

  /// Creates [Pointer<mpv_handle>].
  Future<Pointer<libmpv_bindings.mpv_handle>> create(
    Future<void> Function(Pointer<libmpv_bindings.mpv_event>) callback, {
    Map<String, String> options = const {},
  }) async {
    // Hot-restart tears down the Dart isolate, which invalidates any previously
    // registered `NativeCallable` trampolines. In debug mode, prefer the isolate
    // based implementation to avoid native -> Dart callbacks that can outlive
    // the isolate and crash with "Callback invoked after it has been deleted".
    // See: https://github.com/media-kit/media-kit/issues/1340
    // We still use NativeCallable based implementation in release mode and unit tests for better performance.
    if (kDebugMode && isMainIsolate()) {
      return await InitializerIsolate().create(callback, options: options);
    }
    if (!isExecmemRestricted) {
      return await InitializerNativeCallable(mpv)
          .create(callback, options: options);
    } else {
      return await InitializerIsolate().create(callback, options: options);
    }
  }

  /// Disposes [Pointer<mpv_handle>].
  void dispose(Pointer<libmpv_bindings.mpv_handle> ctx) {
    if (kDebugMode && isMainIsolate()) {
      InitializerIsolate().dispose(mpv, ctx);
      return;
    }
    if (!isExecmemRestricted) {
      InitializerNativeCallable(mpv).dispose(ctx);
    } else {
      InitializerIsolate().dispose(mpv, ctx);
    }
  }

  bool isMainIsolate() {
    final String? name = Isolate.current.debugName;
    return name == 'main';
  }
}
