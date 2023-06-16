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
      result != null,
      'No [VideoControllerInheritedWidget] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(VideoControllerInheritedWidget oldWidget) =>
      identical(controller, oldWidget.controller);
}
