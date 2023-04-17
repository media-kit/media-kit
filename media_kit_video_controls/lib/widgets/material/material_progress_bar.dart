import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video_controls/widgets/media_kit_progress_colors.dart';
import 'package:media_kit_video_controls/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    MediaKitProgressColors? colors,
    Key? key,
  })  : colors = colors ?? MediaKitProgressColors(),
        super(key: key);

  final double height;
  final Player controller;
  final MediaKitProgressColors colors;


  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: 10,
      handleHeight: 6,
      drawShadow: true,
      colors: colors,
    );
  }
}
