import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video_controls/widgets/media_kit_progress_colors.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    MediaKitProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  })  : colors = colors ?? MediaKitProgressColors(),
        super(key: key);

  final Player controller;
  final MediaKitProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  // ignore: library_private_types_in_public_api
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  StreamSubscription? position;
  StreamSubscription? duration;
  bool _controllerWasPlaying = false;

  Player get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    position = controller.streams.position.listen((event) {
      listener();
    });
    duration = controller.streams.duration.listen((event) {
      listener();
    });
  }

  @override
  void deactivate() {
    position?.cancel();
    duration?.cancel();
    super.deactivate();
  }

  void _seekToRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final Offset tapPos = box.globalToLocal(globalPosition);
    final double relative = tapPos.dx / box.size.width;
    final Duration position = controller.state.duration * relative;
    controller.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (controller.state.duration.inMilliseconds == 0) {
          return;
        }
        _controllerWasPlaying = controller.state.playing;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (controller.state.duration.inMilliseconds == 0) {
          return;
        }
        // Should only seek if it's not running on Android, or if it is,
        // then the Player cannot be buffering.
        // On Android, we need to let the player buffer when scrolling
        // in order to let the player buffer. https://github.com/flutter/flutter/issues/101409
        final shouldSeekToRelativePosition =
            !Platform.isAndroid || !controller.state.buffering;
        if (shouldSeekToRelativePosition) {
          _seekToRelativePosition(details.globalPosition);
        }

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        if (controller.state.duration.inMilliseconds == 0) {
          return;
        }
        _seekToRelativePosition(details.globalPosition);
      },
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              value: controller.state,
              colors: widget.colors,
              barHeight: widget.barHeight,
              handleHeight: widget.handleHeight,
              drawShadow: widget.drawShadow,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.value,
    required this.colors,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  });

  PlayerState value;
  MediaKitProgressColors colors;

  final double barHeight;
  final double handleHeight;
  final bool drawShadow;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseOffset = size.height / 2 - barHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(size.width, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (value.duration.inMilliseconds == 0) {
      return;
    }
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    // for (final DurationRange range in value.buffered) {
    //   final double start = range.startFraction(value.duration) * size.width;
    //   final double end = range.endFraction(value.duration) * size.width;
    //   canvas.drawRRect(
    //     RRect.fromRectAndRadius(
    //       Rect.fromPoints(
    //         Offset(start, baseOffset),
    //         Offset(end, baseOffset + barHeight),
    //       ),
    //       const Radius.circular(4.0),
    //     ),
    //     colors.bufferedPaint,
    //   );
    // }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, baseOffset),
          Offset(playedPart, baseOffset + barHeight),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );

    if (drawShadow) {
      final Path shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(playedPart, baseOffset + barHeight / 2),
            radius: handleHeight,
          ),
        );

      canvas.drawShadow(shadowPath, Colors.black, 0.2, false);
    }

    canvas.drawCircle(
      Offset(playedPart, baseOffset + barHeight / 2),
      handleHeight,
      colors.handlePaint,
    );
  }
}
