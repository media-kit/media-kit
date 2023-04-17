import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video_controls/widgets/media_kit_progress_colors.dart';

class VideoProgressBar extends StatefulWidget {
  VideoProgressBar(
    this.controller, {
    MediaKitProgressColors? colors,
    Key? key,
    required this.barHeight,
    required this.handleHeight,
    required this.drawShadow,
  })  : colors = colors ?? MediaKitProgressColors(),
        super(key: key);

  final Player controller;
  final MediaKitProgressColors colors;

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

  Player get controller => widget.controller;

  bool playing = false;
  bool seeking = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration buffer = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    playing = controller.state.playing;
    position = controller.state.position;
    duration = controller.state.duration;
    buffer = controller.state.buffer;
    subscriptions.addAll(
      [
        controller.streams.playing.listen((event) {
          setState(() {
            playing = event;
          });
        }),
        controller.streams.completed.listen((event) {
          setState(() {
            position = Duration.zero;
          });
        }),
        controller.streams.position.listen((event) {
          setState(() {
            if (!seeking) position = event;
          });
        }),
        controller.streams.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
        controller.streams.buffer.listen((event) {
          setState(() {
            buffer = event;
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final s in subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: widget.colors.backgroundColor,
        child: Slider(
          thumbColor: widget.colors.handleColor,
          // overlayColor:widget.colors.backgroundColor ,
          secondaryActiveColor: widget.colors.bufferedColor,
          min: 0.0,
          max: duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds.toDouble().clamp(
                0.0,
                duration.inMilliseconds.toDouble(),
              ),
          secondaryTrackValue: buffer.inMilliseconds.toDouble().clamp(
                0.0,
                duration.inMilliseconds.toDouble(),
              ),
          onChangeStart: (e) {
            seeking = true;
          },
          onChanged: position.inMilliseconds > 0
              ? (e) {
                  setState(() {
                    position = Duration(milliseconds: e ~/ 1);
                  });
                }
              : null,
          onChangeEnd: (e) {
            seeking = false;
            controller.seek(Duration(milliseconds: e ~/ 1));
          },
        ),
      ),
    );
  }
}
