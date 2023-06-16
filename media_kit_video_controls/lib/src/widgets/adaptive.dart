/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// {@template adaptive_video_controls}
///
/// [Video] controls based on the running platform.
///
/// {@endtemplate}
Widget AdaptiveVideoControls(
  BuildContext context,
  VideoController controller,
) {
  return MaterialVideoControls(context, controller);
}