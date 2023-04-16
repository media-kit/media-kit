/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/src/video_controller/web/video_controller_web.dart';
import 'package:media_kit_video/src/video_controller/native/video_controller_native.dart';
import 'package:media_kit_video/src/video_controller/android/video_controller_android.dart';

/// {@template video_controller}
///
/// VideoController
/// ---------------
///
/// This class is used to initialize & handle the video rendering inside the Flutter widget tree.
///
/// A [VideoController] must be created right after creating the [Player] from `package:media_kit`.
/// Pass the [Player] from `package:media_kit` to the [VideoController] constructor.
///
/// ```dart
/// final player = Player();
/// final controller = await VideoController.create(player);
/// ```
///
/// It is important to [dispose] the [VideoController] when it is no longer needed.
/// It will release the allocated resources back to the system.
///
/// You may dynamically resize the video output resolution using the [resize] method.
/// This may yield substantial performance improvements.
///
/// **Notes:**
///
/// 1. You can limit size of the video output by specifying [width] & [height].
///    By default, both [height] & [width] are `null` i.e. output is based on video's resolution.
/// 2. You can switch between GPU & CPU rendering by specifying `enableHardwareAcceleration`.
///    By default, [enableHardwareAcceleration] is `true` i.e. GPU (Direct3D/OpenGL/METAL) is utilized.
///
/// **Additional Notes for Flutter Web:**
///
/// 1. The [width] & [height] parameters are ignored on Flutter Web i.e. render size cannot be changed manually.
/// 2. The [enableHardwareAcceleration] parameter is ignored on Flutter Web i.e. GPU rendering is dependent on the client's web browser.
///
/// {@endtemplate}
abstract class VideoController {
  /// The [Player] instance associated with this [VideoController].
  final Player player;

  /// Fixed width of the video output.
  int? width;

  /// Fixed height of the video output.
  int? height;

  /// Whether hardware acceleration should be enabled or not.
  final bool enableHardwareAcceleration;

  /// Texture ID of the video output, registered with Flutter engine by the native implementation.
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  /// [Rect] of the video output, received from the native implementation.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// {@macro video_controller}
  VideoController(
    this.player,
    this.width,
    this.height, {
    this.enableHardwareAcceleration = true,
  });

  /// {@macro video_controller}
  static Future<VideoController> create(
    Player player, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
  }) {
    if (VideoControllerWeb.supported) {
      return VideoControllerWeb.create(
        player,
        width: width,
        height: height,
        enableHardwareAcceleration: enableHardwareAcceleration,
      );
    } else if (VideoControllerNative.supported) {
      return VideoControllerNative.create(
        player,
        width: width,
        height: height,
        enableHardwareAcceleration: enableHardwareAcceleration,
      );
    } else if (VideoControllerAndroid.supported) {
      return VideoControllerAndroid.create(
        player,
        width: width,
        height: height,
        enableHardwareAcceleration: enableHardwareAcceleration,
      );
    }
    throw UnsupportedError(
      '[VideoController] is not supported on this platform.',
    );
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember, “Premature optimization is the root of all evil”. So, use this method wisely.
  Future<void> setSize({
    int? width,
    int? height,
  });

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  Future<void> dispose();

  @override
  String toString() => 'VideoController('
      'player: $player, '
      'width: $width, '
      'height: $height, '
      'enableHardwareAcceleration: $enableHardwareAcceleration, '
      'id: $id, '
      'rect: $rect'
      ')';
}
