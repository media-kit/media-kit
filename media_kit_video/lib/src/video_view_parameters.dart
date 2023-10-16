import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/src/subtitle/subtitle_view.dart';
import 'package:media_kit_video/src/video/video_texture.dart';
import 'package:media_kit_video/src/video_controller/video_controller.dart';

class VideoViewParameters {
  final VideoController controller;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color fill;
  final Alignment alignment;
  final double? aspectRatio;
  final FilterQuality filterQuality;
  final VideoControlsBuilder? controls;
  final bool wakelock;
  final bool pauseUponEnteringBackgroundMode;
  final bool resumeUponEnteringForegroundMode;
  final SubtitleViewConfiguration subtitleViewConfiguration;
  final Future<void> Function() onEnterFullscreen;
  final Future<void> Function() onExitFullscreen;

  VideoViewParameters({
    required this.controller,
    this.width,
    this.height,
    required this.fit,
    required this.fill,
    required this.alignment,
    this.aspectRatio,
    required this.filterQuality,
    this.controls,
    required this.wakelock,
    required this.pauseUponEnteringBackgroundMode,
    required this.resumeUponEnteringForegroundMode,
    required this.subtitleViewConfiguration,
    required this.onEnterFullscreen,
    required this.onExitFullscreen,
  });

  VideoViewParameters copyWith({
    VideoController? controller,
    double? width,
    double? height,
    BoxFit? fit,
    Color? fill,
    Alignment? alignment,
    double? aspectRatio,
    FilterQuality? filterQuality,
    VideoControlsBuilder? controls,
    bool? wakelock,
    bool? pauseUponEnteringBackgroundMode,
    bool? resumeUponEnteringForegroundMode,
    SubtitleViewConfiguration? subtitleViewConfiguration,
    Future<void> Function()? onEnterFullscreen,
    Future<void> Function()? onExitFullscreen,
  }) {
    return VideoViewParameters(
      controller: controller ?? this.controller,
      width: width ?? this.width,
      height: height ?? this.height,
      fit: fit ?? this.fit,
      fill: fill ?? this.fill,
      alignment: alignment ?? this.alignment,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      filterQuality: filterQuality ?? this.filterQuality,
      controls: controls ?? this.controls,
      wakelock: wakelock ?? this.wakelock,
      pauseUponEnteringBackgroundMode: pauseUponEnteringBackgroundMode ??
          this.pauseUponEnteringBackgroundMode,
      resumeUponEnteringForegroundMode: resumeUponEnteringForegroundMode ??
          this.resumeUponEnteringForegroundMode,
      subtitleViewConfiguration:
          subtitleViewConfiguration ?? this.subtitleViewConfiguration,
      onEnterFullscreen: onEnterFullscreen ?? this.onEnterFullscreen,
      onExitFullscreen: onExitFullscreen ?? this.onExitFullscreen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoViewParameters &&
        other.controller == controller &&
        other.width == width &&
        other.height == height &&
        other.fit == fit &&
        other.fill == fill &&
        other.alignment == alignment &&
        other.aspectRatio == aspectRatio &&
        other.filterQuality == filterQuality &&
        other.controls == controls &&
        other.wakelock == wakelock &&
        other.pauseUponEnteringBackgroundMode ==
            pauseUponEnteringBackgroundMode &&
        other.resumeUponEnteringForegroundMode ==
            resumeUponEnteringForegroundMode &&
        other.subtitleViewConfiguration == subtitleViewConfiguration &&
        other.onEnterFullscreen == onEnterFullscreen &&
        other.onExitFullscreen == onExitFullscreen;
  }

  @override
  int get hashCode {
    return controller.hashCode ^
        width.hashCode ^
        height.hashCode ^
        fit.hashCode ^
        fill.hashCode ^
        alignment.hashCode ^
        aspectRatio.hashCode ^
        filterQuality.hashCode ^
        controls.hashCode ^
        wakelock.hashCode ^
        pauseUponEnteringBackgroundMode.hashCode ^
        resumeUponEnteringForegroundMode.hashCode ^
        subtitleViewConfiguration.hashCode ^
        onEnterFullscreen.hashCode ^
        onExitFullscreen.hashCode;
  }
}
