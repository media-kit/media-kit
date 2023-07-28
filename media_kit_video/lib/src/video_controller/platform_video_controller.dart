/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:media_kit/media_kit.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';

/// {@template platform_video_controller}
///
/// PlatformVideoController
/// -----------------------
///
/// This class provides the interface for platform specific [VideoController] implementations.
/// The platform specific implementations are expected to implement the methods accordingly.
///
/// The subclasses are then used in composition with the [VideoController] class, based on the platform the application is running on.
///
/// {@endtemplate}
abstract class PlatformVideoController {
  /// The [Player] instance associated with this instance.
  final Player player;

  /// User defined configuration for [VideoController].
  final VideoControllerConfiguration configuration;

  /// Texture ID of the video output, registered with Flutter engine by the native implementation.
  final ValueNotifier<int?> id = ValueNotifier<int?>(null);

  /// [Rect] of the video output, received from the native implementation.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// {@macro platform_video_controller}
  PlatformVideoController(
    this.player,
    this.configuration,
  );

  /// Sets the required size of the video output.
  /// This may yield substantial performance improvements if a small [width] & [height] is specified.
  ///
  /// Remember:
  /// * “Premature optimization is the root of all evil”
  /// * “With great power comes great responsibility”
  Future<void> setSize({
    int? width,
    int? height,
  });

  /// A [Future] that completes when the first video frame has been rendered.
  Future<void> get waitUntilFirstFrameRendered =>
      waitUntilFirstFrameRenderedCompleter.future;

  /// [Completer] used to signal the decoding & rendering of the first video frame.
  /// Use [waitUntilFirstFrameRendered] to wait for the first frame to be rendered.
  @protected
  final waitUntilFirstFrameRenderedCompleter = Completer<void>();
}
