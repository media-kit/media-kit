/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/src/video_controller/platform_video_controller.dart';

import 'package:media_kit_video/src/video_controller/native_video_controller/native_video_controller.dart';
import 'package:media_kit_video/src/video_controller/android_video_controller/android_video_controller.dart';
import 'package:media_kit_video/src/video_controller/web_video_controller/web_video_controller.dart';

/// {@template video_controller}
///
/// VideoController
/// ---------------
///
/// [VideoController] is used to initialize & display video output.
/// It takes reference to existing [Player] instance from `package:media_kit`.
///
/// ```dart
/// late final player = Player();
/// late final controller = VideoController(player);
/// ```
///
/// **Notes:**
///
/// 1. You can limit size of the video output by specifying [width] & [height].
///    * By default, both [height] & [width] are `null` i.e. output is based on video's resolution.
/// 2. You can switch between GPU & CPU rendering by specifying `enableHardwareAcceleration`.
///    * By default, [enableHardwareAcceleration] is `true` i.e. GPU (Direct3D/OpenGL/METAL) is utilized.
///
/// **Platform specific differences:**
///
/// 1. [width] & [height] arguments have no effect on Android & Flutter Web.
/// 2. The [enableHardwareAcceleration] argument is ignored on Flutter Web i.e. GPU usage is dependent on the client's web browser.
///
/// {@endtemplate}
class VideoController {
  /// Platform specific internal implementation initialized depending upon the current platform.
  final platform = Completer<PlatformVideoController>();

  /// Platform specific internal implementation initialized depending upon the current platform.
  final notifier = ValueNotifier<PlatformVideoController?>(null);

  /// Texture ID of the video output, registered with Flutter engine by the native implementation.
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  /// [Rect] of the video output, received from the native implementation.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// {@macro platform_video_controller}
  VideoController(
    Player player, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
    VideoControllerConfiguration configuration =
        const VideoControllerConfiguration(),
  }) {
    player.platform?.isVideoControllerAttached = true;

    () async {
      try {
        if (WebVideoController.supported) {
          // TODO(@alexmercerind): Missing implementation.
        } else if (NativeVideoController.supported) {
          final result = await NativeVideoController.create(
            player,
            width,
            height,
            enableHardwareAcceleration,
            configuration,
          );
          platform.complete(result);
          notifier.value = result;
        } else if (AndroidVideoController.supported) {
          final result = await AndroidVideoController.create(
            player,
            enableHardwareAcceleration,
            configuration,
          );
          platform.complete(result);
          notifier.value = result;
        }
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
      if (platform.isCompleted) {
        // Populate [id] & [rect] [ValueNotifier]s with the values from [platform] implementation of [PlatformVideoController].
        final controller = await platform.future;
        // Add listeners.
        void fn0() => id.value = controller.id.value;
        void fn1() => rect.value = controller.rect.value;
        fn0();
        fn1();
        controller.id.addListener(fn0);
        controller.rect.addListener(fn1);
        // Remove listeners upon [Player.dispose].
        player.platform?.release.add(() async {
          controller.id.removeListener(fn0);
          controller.rect.removeListener(fn1);
        });
      } else {
        platform.completeError(
          UnimplementedError(
            '[VideoController] is unavailable for this platform.',
          ),
        );
      }

      if (!(player.platform?.videoControllerCompleter.isCompleted ?? true)) {
        player.platform?.videoControllerCompleter.complete();
      }
    }();
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember:
  /// * “Premature optimization is the root of all evil”
  /// * “With great power comes great responsibility”
  Future<void> setSize({
    int? width,
    int? height,
  }) async {
    final instance = await platform.future;
    return instance.setSize(
      width: width,
      height: height,
    );
  }

  /// A [Future] that completes when the first video frame has been rendered.
  Future<void> get waitUntilFirstFrameRendered async {
    final instance = await platform.future;
    return instance.waitUntilFirstFrameRendered;
  }
}

/// {@template video_controller_configuration}
///
/// VideoControllerConfiguration
/// ----------------------------
/// Configurable options for customizing the [VideoController] behavior.
///
/// {@endtemplate}
class VideoControllerConfiguration {
  /// Sets the [`--vo`](https://mpv.io/manual/stable/#options-vo) property on libmpv backend.
  ///
  /// Default: Platform specific.
  /// * Windows, GNU/Linux, macOS & iOS: `libmpv`
  /// * Android: `gpu`
  final String? vo;

  /// Sets the [`--hwdec`](https://mpv.io/manual/stable/#options-hwdec) property on libmpv backend.
  ///
  /// Default: Platform specific.
  /// * Windows, GNU/Linux, macOS & iOS : `auto`
  /// * Android: `mediacodec-copy`
  final String? hwdec;

  /// {@macro video_controller_configuration}
  const VideoControllerConfiguration({
    this.vo,
    this.hwdec,
  });
}
