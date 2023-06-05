/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'package:flutter/cupertino.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CupertinoVideoControlsTheme extends InheritedWidget {
  const CupertinoVideoControlsTheme({
    super.key,
    required super.child,
  });

  static CupertinoVideoControlsTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CupertinoVideoControlsTheme>();
  }

  static CupertinoVideoControlsTheme of(BuildContext context) {
    final CupertinoVideoControlsTheme? result = maybeOf(context);
    assert(result != null, 'No CupertinoVideoControlsTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CupertinoVideoControlsTheme oldWidget) => false;
}

Widget CupertinoVideoControls(
  BuildContext context,
  VideoController controller,
) {
  final theme = CupertinoVideoControlsTheme.maybeOf(context);
  throw UnimplementedError();
}
