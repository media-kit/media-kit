/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MaterialVideoControlsTheme extends InheritedWidget {
  const MaterialVideoControlsTheme({
    super.key,
    required super.child,
  });

  static MaterialVideoControlsTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MaterialVideoControlsTheme>();
  }

  static MaterialVideoControlsTheme of(BuildContext context) {
    final MaterialVideoControlsTheme? result = maybeOf(context);
    assert(result != null, 'No MaterialVideoControlsTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(MaterialVideoControlsTheme oldWidget) => false;
}

Widget MaterialVideoControls(
  BuildContext context,
  VideoController controller,
) {
  final theme = MaterialVideoControlsTheme.maybeOf(context);
  throw UnimplementedError();
}
