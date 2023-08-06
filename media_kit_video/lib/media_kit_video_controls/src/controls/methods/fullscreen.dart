/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/video_state_inherited_widget.dart';
import 'package:synchronized/synchronized.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/video_controller.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/fullscreen_inherited_widget.dart';

/// Whether a [Video] present in the current [BuildContext] is in fullscreen or not.
bool isFullscreen(BuildContext context) =>
    FullscreenInheritedWidget.maybeOf(context) != null;

/// Makes the [Video] present in the current [BuildContext] enter fullscreen.
Future<void> enterFullscreen(BuildContext context) {
  return lock.synchronized(() async {
    if (!isFullscreen(context)) {
      if (context.mounted) {
        final builder = controlsThemeDataBuilder(context);
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => (builder ?? (e) => e).call(
              VideoStateInheritedWidget(
                state: state(context),
                controlsThemeDataBuilder: builder,
                child: Builder(
                  builder: (context) => FullscreenInheritedWidget(
                    parent: state(context),
                    child: Video(
                      controller: controller(context),
                      // Not required in fullscreen mode:
                      // width: null,
                      // height: null,
                      // Inherit following properties from the parent [Video]:
                      fit: state(context).widget.fit,
                      fill: state(context).widget.fill,
                      alignment: state(context).widget.alignment,
                      aspectRatio: state(context).widget.aspectRatio,
                      filterQuality: state(context).widget.filterQuality,
                      controls: state(context).widget.controls,
                      // Do not acquire or modify existing wakelock in fullscreen mode:
                      wakelock: false,
                    ),
                  ),
                ),
              ),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        await onEnterFullscreen(context)?.call();
      }
    }
  });
}

/// Makes the [Video] present in the current [BuildContext] exit fullscreen.
Future<void> exitFullscreen(BuildContext context) {
  return lock.synchronized(() async {
    if (isFullscreen(context)) {
      if (context.mounted) {
        Navigator.of(context).maybePop();
        // It is known that this [context] will have a [FullscreenInheritedWidget] above it.
        FullscreenInheritedWidget.of(context).parent.refreshView();
      }
      // [exitNativeFullscreen] is moved to [WillPopScope] in [FullscreenInheritedWidget].
      // This is because [exitNativeFullscreen] needs to be called when the user presses the back button.
    }
  });
}

/// Toggles fullscreen for the [Video] present in the current [BuildContext].
Future<void> toggleFullscreen(BuildContext context) {
  if (isFullscreen(context)) {
    return exitFullscreen(context);
  } else {
    return enterFullscreen(context);
  }
}

/// For synchronizing [enterFullscreen] & [exitFullscreen] operations.
final Lock lock = Lock();
