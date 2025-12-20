/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'package:media_kit/ffi/ffi.dart';

import 'package:media_kit/src/player/native/core/initializer.dart';
import 'package:media_kit/src/player/native/core/initializer_isolate.dart';
import 'package:media_kit/src/player/native/core/initializer_native_callable.dart';
import 'package:media_kit/src/player/native/core/native_library.dart';
import 'package:media_kit/src/player/native/core/execmem_restriction.dart';
import 'package:media_kit/src/values.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

MPV? _mpv;
MPV get mpv => _mpv!;

Future<Pointer<mpv_handle>> _createProductionLikeHandle(
  Future<void> Function(Pointer<mpv_event>) callback, {
  Map<String, String> options = const {},
}) {
  // `Initializer` intentionally forces `InitializerIsolate` in debug mode to
  // avoid hot-restart related issues with `NativeCallable` trampolines.
  // These unit tests, however, want to exercise production behavior.
  if (kDebugMode) {
    if (!isExecmemRestricted) {
      return InitializerNativeCallable(mpv).create(callback, options: options);
    }
    return InitializerIsolate().create(callback, options: options);
  }
  return Initializer(mpv).create(callback, options: options);
}

void _disposeProductionLikeHandle(Pointer<mpv_handle> handle) {
  if (kDebugMode) {
    if (!isExecmemRestricted) {
      InitializerNativeCallable(mpv).dispose(handle);
    } else {
      InitializerIsolate().dispose(mpv, handle);
    }
    return;
  }
  Initializer(mpv).dispose(handle);
}

void main() {
  setUp(() {
    NativeLibrary.ensureInitialized();
    _mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
  });
  test(
    'initializer-init',
    () {
      expect(
        _createProductionLikeHandle((_) async {}),
        completes,
      );
    },
  );
  test(
    'initializer-create',
    () {
      expect(
        _createProductionLikeHandle((_) async {}),
        completes,
      );
    },
  );
  test(
    'initializer-dispose',
    () async {
      final handle = await _createProductionLikeHandle((_) async {});
      expect(
        () => _disposeProductionLikeHandle(handle),
        returnsNormally,
      );
    },
  );
  test(
    'initializer-callback',
    () async {
      final shutdown = Completer();

      final expectPauseTrue = expectAsync1((value) {
        print(value);
        expect(value, isTrue);
        shutdown.complete();
      });
      final expectShutdown = expectAsync0(() {
        print('shutdown');
        expect(true, isTrue);
      });

      final handle = await _createProductionLikeHandle(
        (event) async {
          if (event.ref.event_id == mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
            final prop = event.ref.data.cast<mpv_event_property>();
            if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
                prop.ref.format == mpv_format.MPV_FORMAT_FLAG) {
              final value = prop.ref.data.cast<Bool>().value;
              expectPauseTrue(value);
            }
          }
          if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN) {
            expectShutdown();
          }
        },
      );
      await Future.delayed(Duration(seconds: 5));
      {
        final name = 'pause'.toNativeUtf8();
        mpv.mpv_observe_property(
          handle,
          0,
          name.cast(),
          mpv_format.MPV_FORMAT_FLAG,
        );
        calloc.free(name);
      }
      {
        final command = 'cycle pause'.toNativeUtf8();
        mpv.mpv_command_string(
          handle,
          command.cast(),
        );
        calloc.free(command);
      }
      await shutdown.future;
      {
        final command = 'quit 0'.toNativeUtf8();
        mpv.mpv_command_string(
          handle,
          command.cast(),
        );
        calloc.free(command);
      }

      await Future.delayed(const Duration(seconds: 5));

      _disposeProductionLikeHandle(handle);
    },
  );
  test(
    'initializer-options-with-callback',
    () async {
      final handle = await _createProductionLikeHandle(
        (_) async {},
        options: {
          'config': 'yes',
          'config-dir': dirname(Platform.script.toFilePath()),
        },
      );
      {
        final name = 'config'.toNativeUtf8();
        final value = mpv.mpv_get_property_string(
          handle,
          name.cast(),
        );
        calloc.free(name);
        expect(
          value.cast<Utf8>().toDartString(),
          'yes',
        );
      }
      {
        final name = 'config-dir'.toNativeUtf8();
        final value = mpv.mpv_get_property_string(
          handle,
          name.cast(),
        );
        calloc.free(name);
        expect(
          value.cast<Utf8>().toDartString(),
          dirname(Platform.script.toFilePath()),
        );
      }

      await Future.delayed(const Duration(seconds: 5));

      _disposeProductionLikeHandle(handle);
    },
  );
}
