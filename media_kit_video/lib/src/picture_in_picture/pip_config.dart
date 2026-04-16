/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';

/// Configuration for Picture-in-Picture behavior.
///
/// Pass an instance of [PipConfig] to [Video.pip] to enable Picture-in-Picture
/// for that widget. Platform requirements are iOS 15+ and Android 8.0 (API 26)+.
/// On unsupported platforms or OS versions the configuration is ignored and
/// no Picture-in-Picture session is started.
@immutable
class PipConfig {
  /// When `true`, the system may enter Picture-in-Picture automatically when
  /// the application moves to the background. On iOS this maps to
  /// `AVPictureInPictureController.canStartPictureInPictureAutomaticallyFromInline`.
  /// On Android this maps to `Activity.setAutoEnterEnabled` (API 31+).
  final bool autoEnter;

  /// When `true`, Picture-in-Picture is started as soon as the first video
  /// frame is rendered. Ignored when [autoEnter] is `true`.
  final bool startImmediately;

  /// Preferred size of the Picture-in-Picture window.
  ///
  /// On iOS this drives the aspect ratio of `AVSampleBufferDisplayLayer`.
  /// On Android this is mapped to `PictureInPictureParams.setAspectRatio`.
  /// When `null`, the video's intrinsic size (reported by the player) is used.
  final Size? preferredSize;

  const PipConfig({
    this.autoEnter = true,
    this.startImmediately = false,
    this.preferredSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PipConfig &&
          other.autoEnter == autoEnter &&
          other.startImmediately == startImmediately &&
          other.preferredSize == preferredSize);

  @override
  int get hashCode =>
      Object.hash(autoEnter, startImmediately, preferredSize);
}
