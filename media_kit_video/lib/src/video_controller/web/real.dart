/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:ui';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';

/// {@template video_controller_web}
///
/// VideoControllerWeb
/// ------------------
///
/// The [VideoController] implementation based on native C/C++ used on web.
///
/// {@endtemplate}
class VideoControllerWeb extends VideoController {
  /// Whether [VideoControllerNative] is supported on the current platform or not.
  static const bool supported = kIsWeb;

  /// {@macro video_controller_web}
  VideoControllerWeb(
    super.player,
    super.width,
    super.height, {
    super.enableHardwareAcceleration = true,
  });

  /// {@macro video_controller_web}
  static Future<VideoController> create(
    Player player, {
    int? width,
    int? height,
    bool enableHardwareAcceleration = true,
  }) async {
    // Retrieve the native handle of the [Player].
    final handle = await player.handle;

    final controller = VideoControllerWeb(
      player,
      width,
      height,
      enableHardwareAcceleration: enableHardwareAcceleration,
    );

    // Retrieve the [html.VideoElement] instance from [js.context].
    controller._element = js.context[_kInstances][handle];
    // Register the [html.VideoElement] as platform view.
    platformViewRegistry.registerViewFactory(
      'com.alexmercerind.media_kit_video.$handle',
      (int _) => controller._element!,
    );

    // On web implementation, we are having [handle] & [controller.id] same, which in itself is a simple counter based value managed within [Player].
    // Since there is no texture creation or rendering involved.
    controller.id.value = handle;

    // Listen to the resize event of the [html.VideoElement].
    controller._resizeStreamSubscription = controller._element?.onResize.listen(
      (event) {
        debugPrint(
          'media_kit: VideoController: ${controller._element?.videoWidth}, ${controller._element?.videoHeight}',
        );
        // Update the size of the [VideoController].
        controller.rect.value = Rect.fromLTWH(
          0.0,
          0.0,
          controller._element?.videoWidth.toDouble() ?? 0.0,
          controller._element?.videoHeight.toDouble() ?? 0.0,
        );
      },
    );

    // Return the [VideoController].
    return controller;
  }

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember, “Premature optimization is the root of all evil”. So, use this method wisely.
  @override
  Future<void> setSize({
    int? width,
    int? height,
  }) async {
    // N/A
  }

  /// Disposes the [VideoController].
  /// Releases the allocated resources back to the system.
  @override
  Future<void> dispose() async {
    // Close the resize event stream subscription.
    await _resizeStreamSubscription?.cancel();
  }

  /// HTML [html.VideoElement] instance reference.
  html.VideoElement? _element;

  StreamSubscription<html.Event>? _resizeStreamSubscription;

  /// JavaScript object attribute used to store various [VideoElement] instances in [js.context].
  static const _kInstances = '\$com.alexmercerind.media_kit.instances';
}
