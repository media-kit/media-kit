/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_video_controls/src/controls/methods/video_controller.dart';
import 'package:media_kit_video_controls/src/controls/widgets/fullscreen_inherited_widget.dart';

/// Whether a [Video] present in the current [BuildContext] is in fullscreen or not.
bool isFullScreen(BuildContext context) =>
    FullScreenInheritedWidget.maybeOf(context) != null;

/// Makes the [Video] present in the current [BuildContext] enter fullscreen.
Future<void> enterFullScreen(BuildContext context) {
  if (!isFullScreen(context)) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FullScreenInheritedWidget(
          child: Video(
            controller: controller(context),
          ),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
  return Future.value();
}

/// Makes the [Video] present in the current [BuildContext] exit fullscreen.
Future<void> exitFullScreen(BuildContext context) {
  if (isFullScreen(context)) {
    return Navigator.of(context).maybePop();
  }
  return Future.value();
}

/// Toggles fullscreen for the [Video] present in the current [BuildContext].
Future<void> toggleFullScreen(BuildContext context) {
  if (isFullScreen(context)) {
    return exitFullScreen(context);
  } else {
    return enterFullScreen(context);
  }
}
