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
import 'package:media_kit/src/player/native/core/native_library.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

MPV? _mpv;
MPV get mpv => _mpv!;

void main() {
  setUp(() {
    NativeLibrary.ensureInitialized();
    _mpv = MPV(DynamicLibrary.open(NativeLibrary.path));
  });
  test(
    'initializer-init',
    () {
      expect(
        Initializer(mpv).create((_) async {}),
        completes,
      );
    },
  );
  test(
    'initializer-create',
    () {
      expect(
        Initializer(mpv).create((_) async {}),
        completes,
      );
    },
  );
  test(
    'initializer-dispose',
    () async {
      final handle = await Initializer(mpv).create((_) async {});
      expect(
        () => Initializer(mpv).dispose(handle),
        returnsNormally,
      );
    },
  );
  test('initializer-callback', () async {
    final initialPause = Completer<bool>();
    final paused = Completer<void>();
    final shutdown = Completer<void>();
    final values = <bool>[];
    final handle = await Initializer(mpv).create((event) async {
      if (event.ref.event_id == mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
        final prop = event.ref.data.cast<mpv_event_property>();
        if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
            prop.ref.format == mpv_format.MPV_FORMAT_FLAG) {
          final value = prop.ref.data.cast<Int32>().value != 0;
          values.add(value);
          if (!initialPause.isCompleted) initialPause.complete(value);
          if (value && !paused.isCompleted) paused.complete();
        }
      }
      if (event.ref.event_id == mpv_event_id.MPV_EVENT_SHUTDOWN &&
          !shutdown.isCompleted) {
        shutdown.complete();
      }
    }, options: {'config': 'no', 'pause': 'no'});

    int command(String value) {
      final pointer = value.toNativeUtf8();
      try {
        return mpv.mpv_command_string(handle, pointer.cast());
      } finally {
        calloc.free(pointer);
      }
    }

    try {
      final name = 'pause'.toNativeUtf8();
      try {
        expect(
          mpv.mpv_observe_property(
              handle, 0, name.cast(), mpv_format.MPV_FORMAT_FLAG),
          greaterThanOrEqualTo(0),
        );
      } finally {
        calloc.free(name);
      }
      // Observing a property reports its current value before later changes.
      // Wait for that notification so mpv cannot coalesce it with the update.
      expect(await initialPause.future.timeout(const Duration(seconds: 5)),
          isFalse);
      expect(command('set pause yes'), greaterThanOrEqualTo(0));
      await paused.future.timeout(const Duration(seconds: 5));
      expect(values, containsAllInOrder([false, true]));
      expect(command('quit 0'), greaterThanOrEqualTo(0));
      await shutdown.future.timeout(const Duration(seconds: 5));
    } finally {
      if (!shutdown.isCompleted) command('quit 0');
      Initializer(mpv).dispose(handle);
    }
  });
  test(
    'initializer-options-with-callback',
    () async {
      final handle = await Initializer(mpv).create(
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

      Initializer(mpv).dispose(handle);
    },
  );
}
