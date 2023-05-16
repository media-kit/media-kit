/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';

// Stub declaration for avoiding compilation errors on Dart JS using conditional imports.

class VideoControllerAndroid extends VideoController {
  static const bool supported = false;

  VideoControllerAndroid(
    super.player,
    super.width,
    super.height,
    super.enableHardwareAcceleration,
  );

  static Future<VideoController> create(
    Player player, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> dispose() => throw UnimplementedError();

  @override
  Future<void> setSize({int? width, int? height}) => throw UnimplementedError();
}
