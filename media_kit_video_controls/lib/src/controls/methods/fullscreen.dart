/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_video_controls/src/controls/widgets/fullscreen_inherited_widget.dart';

/// Whether a [Video] present in the current [BuildContext] is in fullscreen or not.
bool isFullscreen(BuildContext context) =>
    FullscreenInheritedWidget.maybeOf(context) != null;

/// Makes the [Video] present in the current [BuildContext] enter fullscreen.
Future<void> enterFullscreen(
  VideoController controller,
  BuildContext context,
) {
  return lock.synchronized(() async {
    if (!isFullscreen(context)) {
      if (context.mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => FullscreenInheritedWidget(
              child: Video(
                controller: controller,
              ),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        await enterNativeFullscreen();
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
      }
      await exitNativeFullscreen();
    }
  });
}

/// Toggles fullscreen for the [Video] present in the current [BuildContext].
Future<void> toggleFullscreen(
  VideoController controller,
  BuildContext context,
) {
  if (isFullscreen(context)) {
    return exitFullscreen(context);
  } else {
    return enterFullscreen(controller, context);
  }
}

/// Makes the native window enter fullscreen.
Future<void> enterNativeFullscreen() async {
  if (kIsWeb) {
    // TODO: Missing implementation.
  } else if (Platform.isAndroid) {
    await Future.wait(
      [
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        SystemChrome.setPreferredOrientations(
          [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        ),
      ],
    );
  } else if (Platform.isIOS) {
    await Future.wait(
      [
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        SystemChrome.setPreferredOrientations(
          [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        ),
      ],
    );
  }
}

/// Makes the native window exit fullscreen.
Future<void> exitNativeFullscreen() async {
  if (kIsWeb) {
    // TODO: Missing implementation.
  } else if (Platform.isAndroid) {
    await Future.wait(
      [
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
        SystemChrome.setPreferredOrientations([]),
      ],
    );
  } else if (Platform.isIOS) {
    await Future.wait(
      [
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        SystemChrome.setPreferredOrientations(
          [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        ),
      ],
    );
  }
}

/// For synchronizing [enterFullscreen] & [exitFullscreen] operations.
final Lock lock = Lock();
