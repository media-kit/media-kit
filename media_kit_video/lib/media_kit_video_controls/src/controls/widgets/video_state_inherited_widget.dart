/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template video_state_inherited_widget}
///
/// Inherited widget which provides [VideoState] associated with the parent [Video] widget to descendant widgets.
///
/// {@endtemplate}
class VideoStateInheritedWidget extends InheritedWidget {
  final VideoState state;
  final Widget Function(Widget)? controlsThemeDataBuilder;
  const VideoStateInheritedWidget({
    super.key,
    required this.state,
    required this.controlsThemeDataBuilder,
    required super.child,
  });

  static VideoStateInheritedWidget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VideoStateInheritedWidget>();
  }

  static VideoStateInheritedWidget of(BuildContext context) {
    final VideoStateInheritedWidget? result = maybeOf(context);
    assert(
      result != null,
      'No [VideoStateInheritedWidget] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(VideoStateInheritedWidget oldWidget) =>
      identical(state, oldWidget.state) &&
      identical(controlsThemeDataBuilder, oldWidget.controlsThemeDataBuilder);
}
