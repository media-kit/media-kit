/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Returns the video controls theme data builder associated with the [Video] present in the current [BuildContext].
Widget Function(Widget)? controlsThemeDataBuilder(BuildContext context) =>
    ControlsThemeDataBuilderInheritedWidget.maybeOf(context)
        ?.controlsThemeDataBuilder;
