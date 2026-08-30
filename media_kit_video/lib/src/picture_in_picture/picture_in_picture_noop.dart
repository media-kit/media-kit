/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';

import 'package:media_kit_video/src/picture_in_picture/pip_event.dart';
import 'package:media_kit_video/src/picture_in_picture/picture_in_picture_controller.dart';

/// No-op [PictureInPictureController] used on platforms / OS versions that
/// do not support Picture-in-Picture (desktop, web, iOS < 15, Android < 26).
class PictureInPictureNoop implements PictureInPictureController {
  const PictureInPictureNoop();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> isActive() async => false;

  @override
  Future<void> start({
    required int handle,
    required Size videoSize,
    bool autoEnter = true,
    bool startImmediately = false,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setAutoEnter({required bool enabled}) async {}

  @override
  Stream<PipEvent> get events => const Stream.empty();
}
