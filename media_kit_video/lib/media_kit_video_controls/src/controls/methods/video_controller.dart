/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/video_state_inherited_widget.dart';

/// Returns the [VideoState] associated with the [Video] present in the current [BuildContext].
VideoState state(BuildContext context) =>
    VideoStateInheritedWidget.of(context).state;

/// Returns the [VideoController] associated with the [Video] present in the current [BuildContext].
VideoController controller(BuildContext context) =>
    VideoStateInheritedWidget.of(context).state.widget.controller;

/// Returns the video controls theme data builder associated with the [Video] present in the current [BuildContext].
Widget Function(Widget)? controlsThemeDataBuilder(BuildContext context) =>
    VideoStateInheritedWidget.of(context).controlsThemeDataBuilder;
