/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template video_controller_inherited_widget}
///
/// Inherited widget which provides [VideoController] associated with the parent [Video] widget to descendant widgets.
///
/// {@endtemplate}
class VideoControllerInheritedWidget extends InheritedWidget {
  final VideoController controller;
  const VideoControllerInheritedWidget({
    super.key,
    required this.controller,
    required super.child,
  });

  static VideoControllerInheritedWidget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VideoControllerInheritedWidget>();
  }

  static VideoControllerInheritedWidget of(BuildContext context) {
    final VideoControllerInheritedWidget? result = maybeOf(context);
    assert(
        result != null, 'No VideoControllerInheritedWidget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(VideoControllerInheritedWidget oldWidget) =>
      identical(controller, oldWidget.controller);
}

/// [VideoController] available in this [context].
VideoController controller(BuildContext context) =>
    VideoControllerInheritedWidget.of(context).controller;

/// Extension methods for [Duration].
extension DurationExtension on Duration {
  /// Returns a [String] representation of [Duration].
  String label({Duration? reference}) {
    reference ??= this;
    if (reference > const Duration(days: 1)) {
      final days = inDays.toString().padLeft(3, '0');
      final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (reference > const Duration(hours: 1)) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = inMinutes.toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }
}
