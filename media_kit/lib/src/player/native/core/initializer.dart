/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:isolate';

import 'package:media_kit/generated/libmpv/bindings.dart' as generated;
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
  /// Singleton instance.
  static Initializer? _instance;

  /// {@macro initializer}
  Initializer._(this.mpv);

  /// {@macro initializer}
  factory Initializer(generated.MPV mpv) {
    _instance ??= Initializer._(mpv);
    return _instance!;
  }

  /// Generated libmpv C API bindings.
  final generated.MPV mpv;

  /// Creates [Pointer<mpv_handle>].
  Future<Pointer<generated.mpv_handle>> create(
    Future<void> Function(Pointer<generated.mpv_event>) callback, {
    Map<String, String> options = const {},
  }) async {
    // In debug mode (main isolate), use isolate-based event loop to avoid
    // NativeCallable trampolines that crash on hot restart in Flutter 3.38+.
    // The isolate approach polls with mpv_wait_event and never registers a
    // wakeup callback, so there is nothing to become stale across restarts.
    // NativeCallable is still used in release/profile mode (no hot restart)
    // and in unit test isolates (to test the production code path).
    // See: https://github.com/media-kit/media-kit/issues/1340
    if (kDebugMode && _isMainIsolate) {
      return InitializerIsolate().create(callback, options: options);
    }
    if (!isExecmemRestricted) {
      return InitializerNativeCallable(mpv).create(callback, options: options);
    } else {
      return InitializerIsolate().create(callback, options: options);
    }
  }

  /// Disposes [Pointer<mpv_handle>].
  void dispose(Pointer<generated.mpv_handle> ctx) {
    if (kDebugMode && _isMainIsolate) {
      InitializerIsolate().dispose(mpv, ctx);
      return;
    }
    if (!isExecmemRestricted) {
      InitializerNativeCallable(mpv).dispose(ctx);
    } else {
      InitializerIsolate().dispose(mpv, ctx);
    }
  }

  /// Whether the current isolate is the main app isolate.
  /// Unit test isolates have different names, so they still use NativeCallable.
  static final bool _isMainIsolate = Isolate.current.debugName == 'main';
}
