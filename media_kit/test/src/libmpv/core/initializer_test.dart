/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:media_kit/src/libmpv/core/initializer.dart';
import 'package:media_kit/src/libmpv/core/native_library.dart';

import 'package:media_kit/generated/libmpv/bindings.dart';

void main() {
  setUp(NativeLibrary.ensureInitialized);
  test(
    'initializer-create',
    () async {
      expect(
        create(NativeLibrary.path, (_) async {}),
        completes,
      );
    },
  );
  test(
    'initializer-callback',
    () async {
      final mpv = MPV(DynamicLibrary.open(NativeLibrary.path));

      bool pause = false;

      final expectPauseFalse = expectAsync0(() {
        print(pause);
        expect(pause, isFalse);
      });
      final expectPauseTrue = expectAsync0(() {
        print(pause);
        expect(pause, isTrue);
      });

      final handle = await create(
        NativeLibrary.path,
        (event) async {
          if (event.ref.event_id == mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
            final prop = event.ref.data.cast<mpv_event_property>();
            if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
                prop.ref.format == mpv_format.MPV_FORMAT_FLAG) {
              final value = prop.ref.data.cast<Bool>().value;
              pause = value;
              if (value) {
                expectPauseTrue();
              }
              if (!value) {
                expectPauseFalse();
              }
            }
          }
        },
      );
      await Future.delayed(Duration(seconds: 1));
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
    },
  );
}
