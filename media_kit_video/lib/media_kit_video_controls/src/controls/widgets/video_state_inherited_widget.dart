/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template video_state_inherited_widget}
///
/// Inherited widget which provides [VideoState] associated with the parent [Video] widget to descendant widgets.
///
/// {@endtemplate}
class VideoStateInheritedWidget extends InheritedWidget {
  final VideoState state;
  final ValueNotifier<BuildContext?> contextNotifier;
  final ValueNotifier<VideoViewParameters> videoViewParametersNotifier;
  VideoStateInheritedWidget({
    super.key,
    required this.state,
    required this.contextNotifier,
    required this.videoViewParametersNotifier,
    required Widget child,
  }) : super(
          child: _VideoStateInheritedWidgetContextNotifier(
            state: state,
            contextNotifier: contextNotifier,
            videoViewParametersNotifier: videoViewParametersNotifier,
            child: child,
          ),
        );

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
      identical(contextNotifier, oldWidget.contextNotifier);
}

/// {@template video_state_inherited_widget_context_notifier}
///
/// This widget is used to notify the [VideoState._contextNotifier] about the most recent [BuildContext] associated with the [Video] widget.
///
/// {@endtemplate}
class _VideoStateInheritedWidgetContextNotifier extends StatefulWidget {
  final VideoState state;
  final ValueNotifier<BuildContext?> contextNotifier;
  final ValueNotifier<VideoViewParameters?> videoViewParametersNotifier;

  final Widget child;

  const _VideoStateInheritedWidgetContextNotifier({
    required this.state,
    required this.contextNotifier,
    required this.videoViewParametersNotifier,
    required this.child,
  });

  @override
  State<_VideoStateInheritedWidgetContextNotifier> createState() =>
      _VideoStateInheritedWidgetContextNotifierState();
}

class _VideoStateInheritedWidgetContextNotifierState
    extends State<_VideoStateInheritedWidgetContextNotifier> {
  static final _fallback = HashMap<VideoState, BuildContext>.identity();

  @override
  void dispose() {
    // Restore the original [BuildContext] associated with this [Video] widget.
    widget.contextNotifier.value = _fallback[widget.state];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only update the [BuildContext] associated with this [Video] widget if it is not already set or if the [Video] widget is in fullscreen mode.
    // This is being done because the [Video] widget is rebuilt when it enters/exits fullscreen mode... & things don't work properly if we let [BuildContext] update in every rebuild.
    if (widget.contextNotifier.value == null || isFullscreen(context)) {
      widget.contextNotifier.value = context;
      _fallback[widget.state] ??= context;
    }

    return widget.child;
  }
}
