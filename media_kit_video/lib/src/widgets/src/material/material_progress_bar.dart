import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/src/widgets/src/media_kit_progress_colors.dart';
import 'package:media_kit_video/src/widgets/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    MediaKitProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
  })  : colors = colors ?? MediaKitProgressColors(),
        super(key: key);

  final double height;
  final Player controller;
  final MediaKitProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: 10,
      handleHeight: 6,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
    );
  }
}
