/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2023 & onwards, Abdelaziz Mahdy <abdelaziz.h.mahdy@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:media_kit_video/src/video/video.dart';
import 'package:media_kit_video/src/subtitle/subtitle_view.dart';

/// {@template video_view_parameters}
///
/// VideoViewParameters
/// -------------------
///
/// The attributes of a [Video] widget composed into a single class.
///
/// {@endtemplate}
class VideoViewParameters {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color fill;
  final Alignment alignment;
  final double? aspectRatio;
  final FilterQuality filterQuality;
  final /* VideoControlsBuilder? */ dynamic controls;
  final SubtitleViewConfiguration subtitleViewConfiguration;

  /// {@macro video_view_parameters}
  VideoViewParameters({
    required this.width,
    required this.height,
    required this.fit,
    required this.fill,
    required this.alignment,
    required this.aspectRatio,
    required this.filterQuality,
    required this.controls,
    required this.subtitleViewConfiguration,
  });

  VideoViewParameters copyWith({
    required double? width,
    required double? height,
    required BoxFit fit,
    required Color fill,
    required Alignment alignment,
    required double? aspectRatio,
    required FilterQuality filterQuality,
    /* VideoControlsBuilder? */ required dynamic controls,
    required bool? pauseUponEnteringBackgroundMode,
    required bool? resumeUponEnteringForegroundMode,
    required SubtitleViewConfiguration subtitleViewConfiguration,
    required Future<void> Function()? onEnterFullscreen,
    required Future<void> Function()? onExitFullscreen,
  }) {
    return VideoViewParameters(
      width: width,
      height: height,
      fit: fit,
      fill: fill,
      alignment: alignment,
      aspectRatio: aspectRatio,
      filterQuality: filterQuality,
      controls: controls,
      subtitleViewConfiguration: subtitleViewConfiguration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoViewParameters &&
          other.width == width &&
          other.height == height &&
          other.fit == fit &&
          other.fill == fill &&
          other.alignment == alignment &&
          other.aspectRatio == aspectRatio &&
          other.filterQuality == filterQuality &&
          other.controls == controls &&
          other.subtitleViewConfiguration == subtitleViewConfiguration;

  @override
  int get hashCode =>
      width.hashCode ^
      height.hashCode ^
      fit.hashCode ^
      fill.hashCode ^
      alignment.hashCode ^
      aspectRatio.hashCode ^
      filterQuality.hashCode ^
      controls.hashCode ^
      subtitleViewConfiguration.hashCode;
}
