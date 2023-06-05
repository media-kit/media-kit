/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video_controls/src/utils.dart';

/// {@template material_video_controls}
///
/// [Video] controls which use Material design.
///
/// {@endtemplate}
Widget MaterialVideoControls(
  BuildContext context,
  VideoController controller,
) {
  final data = MaterialVideoControlsTheme.maybeOf(context)?.data ??
      const MaterialVideoControlsThemeData();
  return _MaterialVideoControls(controller: controller, data: data);
}

/// {@template material_video_controls_theme_data}
///
/// Theming related data for [MaterialVideoControls]. These values are used to theme the descendant [MaterialVideoControls].
///
/// {@endtemplate}
class MaterialVideoControlsThemeData {
  // GENERIC

  /// [Duration] after which the controls will be hidden when there is no mouse movement.
  final Duration controlsHoverDuration;

  /// [Duration] for which the controls will be animated when shown or hidden.
  final Duration controlsTransitionDuration;

  // SEEK BAR

  /// [Duration] for which the seek bar will be animated when the user seeks.
  final Duration seekBarTransitionDuration;

  /// [Duration] for which the seek bar thumb will be animated when the user seeks.
  final Duration seekBarThumbTransitionDuration;

  /// Margin around the seek bar.
  final EdgeInsets seekBarMargin;

  /// Height of the seek bar.
  final double seekBarHeight;

  /// Height of the seek bar when hovered.
  final double seekBarHoverHeight;

  /// Height of the seek bar [Container].
  final double seekBarContainerHeight;

  /// [Color] of the seek bar.
  final Color seekBarColor;

  /// [Color] of the hovered section in the seek bar.
  final Color seekBarHoverColor;

  /// [Color] of the playback position section in the seek bar.
  final Color seekBarPositionColor;

  /// [Color] of the playback buffer section in the seek bar.
  final Color seekBarBufferColor;

  /// Size of the seek bar thumb.
  final double seekBarThumbSize;

  /// [Color] of the seek bar thumb.
  final Color seekBarThumbColor;

  // BOTTOM BUTTON BAR

  /// Margin around the bottom button bar.
  final EdgeInsets bottomButtonBarMargin;

  /// Height of the bottom button bar.
  final double bottomButtonBarHeight;

  /// Size of the bottom button bar buttons.
  final double bottomButtonBarButtonSize;

  /// Color of the bottom button bar buttons.
  final Color bottomButtonBarButtonColor;

  /// Custom bottom button bar builder.
  /// This will override the default bottom button bar.
  final List<Widget> Function(BuildContext context, VideoController controller)?
      bottomButtonBarBuilder;

  // VOLUME BAR

  /// [Color] of the volume bar.
  final Color volumeBarColor;

  /// [Color] of the active region in the volume bar.
  final Color volumeBarActiveColor;

  /// Size of the volume bar thumb.
  final double volumeBarThumbSize;

  /// [Color] of the volume bar thumb.
  final Color volumeBarThumbColor;

  /// [Duration] for which the volume bar will be animated when the user hovers.
  final Duration volumeBarTransitionDuration;

  // VISIBILITY

  /// Whether a skip next button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipNextButton;

  /// Whether a skip previous button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipPreviousButton;

  /// Whether to show skip next button.
  final bool showSkipNextButton;

  /// Whether to show skip previous button.
  final bool showSkipPreviousButton;

  /// Whether to show volume button.
  final bool showVolumeButton;

  /// Whether to show position indicator.
  final bool showPositionIndicator;

  const MaterialVideoControlsThemeData({
    this.controlsHoverDuration = const Duration(seconds: 3),
    this.controlsTransitionDuration = const Duration(milliseconds: 150),
    this.seekBarTransitionDuration = const Duration(milliseconds: 300),
    this.seekBarThumbTransitionDuration = const Duration(milliseconds: 150),
    this.seekBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.seekBarHeight = 3.2,
    this.seekBarHoverHeight = 5.6,
    this.seekBarContainerHeight = 36.0,
    this.seekBarColor = const Color(0x3DFFFFFF),
    this.seekBarHoverColor = const Color(0x3DFFFFFF),
    this.seekBarPositionColor = const Color(0xFFFF0000),
    this.seekBarBufferColor = const Color(0x3DFFFFFF),
    this.seekBarThumbSize = 12.0,
    this.seekBarThumbColor = const Color(0xFFFF0000),
    this.bottomButtonBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.bottomButtonBarHeight = 56.0,
    this.bottomButtonBarButtonSize = 28.0,
    this.bottomButtonBarButtonColor = const Color(0xFFFFFFFF),
    this.bottomButtonBarBuilder,
    this.volumeBarColor = const Color(0x3DFFFFFF),
    this.volumeBarActiveColor = const Color(0xFFFFFFFF),
    this.volumeBarThumbSize = 12.0,
    this.volumeBarThumbColor = const Color(0xFFFFFFFF),
    this.volumeBarTransitionDuration = const Duration(milliseconds: 150),
    this.automaticallyImplySkipNextButton = true,
    this.automaticallyImplySkipPreviousButton = true,
    this.showSkipNextButton = false,
    this.showSkipPreviousButton = false,
    this.showVolumeButton = true,
    this.showPositionIndicator = true,
  });
}

/// {@template material_video_controls_theme}
///
/// Inherited widget which provides [MaterialVideoControlsThemeData] to descendant widgets.
///
/// {@endtemplate}
class MaterialVideoControlsTheme extends InheritedWidget {
  final MaterialVideoControlsThemeData data;
  const MaterialVideoControlsTheme({
    super.key,
    required this.data,
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
  bool updateShouldNotify(MaterialVideoControlsTheme oldWidget) =>
      data != oldWidget.data;
}

/// {@macro material_video_controls}
class _MaterialVideoControls extends StatefulWidget {
  final VideoController controller;
  final MaterialVideoControlsThemeData data;
  const _MaterialVideoControls({
    Key? key,
    required this.controller,
    required this.data,
  }) : super(key: key);

  @override
  State<_MaterialVideoControls> createState() => _MaterialVideoControlsState();
}

/// {@macro material_video_controls}
class _MaterialVideoControlsState extends State<_MaterialVideoControls> {
  bool visible = false;

  Timer? _timer;

  late var playlist = widget.controller.player.state.playlist;

  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    subscriptions.addAll(
      [
        widget.controller.player.streams.playlist.listen(
          (event) {
            setState(() {
              playlist = event;
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void onHover() {
    setState(() {
      visible = true;
    });
    _timer?.cancel();
    _timer = Timer(widget.data.controlsHoverDuration, () {
      setState(() {
        visible = false;
      });
    });
  }

  void onEnter() {
    setState(() {
      visible = true;
    });
    _timer?.cancel();
    _timer = Timer(widget.data.controlsHoverDuration, () {
      setState(() {
        visible = false;
      });
    });
  }

  void onExit() {
    setState(() {
      visible = false;
    });
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => onHover(),
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: widget.data.controlsTransitionDuration,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [
                    0.5,
                    1.0,
                  ],
                  colors: [
                    Colors.transparent,
                    Colors.black38,
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0.0, 16.0),
                  child: _MaterialSeekBar(
                    data: widget.data,
                    controller: widget.controller,
                  ),
                ),
                Container(
                  height: widget.data.bottomButtonBarHeight,
                  margin: widget.data.bottomButtonBarMargin,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: widget.data.bottomButtonBarBuilder
                            ?.call(context, widget.controller) ??
                        [
                          if ((widget.data
                                      .automaticallyImplySkipPreviousButton &&
                                  playlist.medias.length > 1) ||
                              widget.data.showSkipPreviousButton)
                            IconButton(
                              onPressed: widget.controller.player.previous,
                              iconSize: widget.data.bottomButtonBarButtonSize,
                              icon: const Icon(Icons.skip_previous),
                              color: Colors.white,
                            ),
                          _PlayOrPauseButton(
                            data: widget.data,
                            controller: widget.controller,
                          ),
                          if ((widget.data.automaticallyImplySkipNextButton &&
                                  playlist.medias.length > 1) ||
                              widget.data.showSkipPreviousButton)
                            IconButton(
                              onPressed: widget.controller.player.next,
                              iconSize: widget.data.bottomButtonBarButtonSize,
                              icon: const Icon(Icons.skip_next),
                              color: Colors.white,
                            ),
                          _VolumeButton(
                            data: widget.data,
                            controller: widget.controller,
                          ),
                          _PositionIndicator(
                            data: widget.data,
                            controller: widget.controller,
                          ),
                          const Spacer(),
                        ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// SEEK BAR

class _MaterialSeekBar extends StatefulWidget {
  final MaterialVideoControlsThemeData data;
  final VideoController controller;
  const _MaterialSeekBar({
    Key? key,
    required this.data,
    required this.controller,
  }) : super(key: key);

  @override
  State<_MaterialSeekBar> createState() => _MaterialSeekBarState();
}

class _MaterialSeekBarState extends State<_MaterialSeekBar> {
  bool hover = false;
  bool click = false;
  double slider = 0.0;

  late bool playing = widget.controller.player.state.playing;
  late Duration position = widget.controller.player.state.position;
  late Duration duration = widget.controller.player.state.duration;
  late Duration buffer = widget.controller.player.state.buffer;

  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    subscriptions.addAll(
      [
        widget.controller.player.streams.playing.listen((event) {
          setState(() {
            playing = event;
          });
        }),
        widget.controller.player.streams.completed.listen((event) {
          setState(() {
            position = Duration.zero;
          });
        }),
        widget.controller.player.streams.position.listen((event) {
          setState(() {
            if (!click) position = event;
          });
        }),
        widget.controller.player.streams.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
        widget.controller.player.streams.buffer.listen((event) {
          setState(() {
            buffer = event;
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void onPointerMove(PointerMoveEvent e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      hover = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onPointerDown() {
    setState(() {
      click = true;
    });
  }

  void onPointerUp() {
    setState(() {
      click = false;
    });
    widget.controller.player.seek(duration * slider);
  }

  void onHover(PointerHoverEvent e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      hover = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onEnter(PointerEnterEvent e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      hover = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onExit(PointerExitEvent e, BoxConstraints constraints) {
    setState(() {
      hover = false;
      slider = 0.0;
    });
  }

  /// Returns the current playback position in percentage.
  double get positionPercent {
    if (position == Duration.zero || duration == Duration.zero) {
      return 0.0;
    } else {
      final value = position.inMilliseconds / duration.inMilliseconds;
      return value.clamp(0.0, 1.0);
    }
  }

  /// Returns the current playback buffer position in percentage.
  double get bufferPercent {
    if (buffer == Duration.zero || duration == Duration.zero) {
      return 0.0;
    } else {
      final value = buffer.inMilliseconds / duration.inMilliseconds;
      return value.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      margin: widget.data.seekBarMargin,
      child: LayoutBuilder(
        builder: (context, constraints) => MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) => onHover(e, constraints),
          onEnter: (e) => onEnter(e, constraints),
          onExit: (e) => onExit(e, constraints),
          child: Listener(
            onPointerMove: (e) => onPointerMove(e, constraints),
            onPointerDown: (e) => onPointerDown(),
            onPointerUp: (e) => onPointerUp(),
            child: Container(
              color: Colors.transparent,
              width: constraints.maxWidth,
              height: widget.data.seekBarContainerHeight,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedContainer(
                    width: constraints.maxWidth,
                    height: hover
                        ? widget.data.seekBarHoverHeight
                        : widget.data.seekBarHeight,
                    alignment: Alignment.centerLeft,
                    duration: widget.data.seekBarThumbTransitionDuration,
                    color: widget.data.seekBarColor,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          width: constraints.maxWidth * slider,
                          color: widget.data.seekBarHoverColor,
                        ),
                        Container(
                          width: constraints.maxWidth * bufferPercent,
                          color: widget.data.seekBarBufferColor,
                        ),
                        Container(
                          width: click
                              ? constraints.maxWidth * slider
                              : constraints.maxWidth * positionPercent,
                          color: widget.data.seekBarPositionColor,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: click
                        ? (constraints.maxWidth -
                                widget.data.seekBarThumbSize / 2) *
                            slider
                        : (constraints.maxWidth -
                                widget.data.seekBarThumbSize / 2) *
                            positionPercent,
                    child: AnimatedContainer(
                      width:
                          hover || click ? widget.data.seekBarThumbSize : 0.0,
                      height:
                          hover || click ? widget.data.seekBarThumbSize : 0.0,
                      duration: widget.data.seekBarThumbTransitionDuration,
                      decoration: BoxDecoration(
                        color: widget.data.seekBarThumbColor,
                        borderRadius: BorderRadius.circular(
                          widget.data.seekBarThumbSize / 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// BUTTONS

class _PlayOrPauseButton extends StatefulWidget {
  final MaterialVideoControlsThemeData data;
  final VideoController controller;
  const _PlayOrPauseButton({
    required this.data,
    required this.controller,
  });

  @override
  State<StatefulWidget> createState() => _PlayOrPauseButtonState();
}

class _PlayOrPauseButtonState extends State<_PlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    value: widget.controller.player.state.playing ? 1 : 0,
    duration: const Duration(milliseconds: 200),
  );

  StreamSubscription<bool>? subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.controller.player.streams.playing.listen((event) {
      if (event) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.controller.player.playOrPause,
      iconSize: widget.data.bottomButtonBarButtonSize,
      color: widget.data.bottomButtonBarButtonColor,
      icon: AnimatedIcon(
        progress: controller,
        icon: AnimatedIcons.play_pause,
        size: widget.data.bottomButtonBarButtonSize,
        color: widget.data.bottomButtonBarButtonColor,
      ),
    );
  }
}

class _VolumeButton extends StatefulWidget {
  final MaterialVideoControlsThemeData data;
  final VideoController controller;
  const _VolumeButton({
    Key? key,
    required this.data,
    required this.controller,
  }) : super(key: key);

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<_VolumeButton>
    with SingleTickerProviderStateMixin {
  late double volume = widget.controller.player.state.volume;

  StreamSubscription<double>? subscription;

  bool hover = false;

  bool mute = false;
  double _volume = 0.0;

  @override
  void initState() {
    super.initState();
    subscription = widget.controller.player.streams.volume.listen((event) {
      setState(() {
        volume = event;
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          hover = true;
        });
      },
      onExit: (e) {
        setState(() {
          hover = false;
        });
      },
      child: Row(
        children: [
          const SizedBox(width: 4.0),
          IconButton(
            onPressed: () async {
              if (mute) {
                await widget.controller.player.setVolume(_volume);
              } else {
                _volume = volume;
                await widget.controller.player.setVolume(0.0);
              }
              mute = !mute;
              setState(() {});
            },
            iconSize: widget.data.bottomButtonBarButtonSize * 0.8,
            color: widget.data.bottomButtonBarButtonColor,
            icon: Icon(
              mute || volume == 0.0
                  ? Icons.volume_off
                  : volume < 0.5
                      ? Icons.volume_down
                      : Icons.volume_up,
            ),
          ),
          AnimatedOpacity(
            opacity: hover ? 1.0 : 0.0,
            duration: widget.data.volumeBarTransitionDuration,
            child: AnimatedContainer(
              width: hover ? (12.0 + 52.0 + 18.0) : 12.0,
              duration: widget.data.volumeBarTransitionDuration,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 12.0),
                    SizedBox(
                      width: 52.0,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 1.2,
                          inactiveTrackColor: widget.data.volumeBarColor,
                          activeTrackColor: widget.data.volumeBarActiveColor,
                          thumbColor: widget.data.volumeBarThumbColor,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius:
                                widget.data.volumeBarThumbSize / 2,
                            elevation: 0.0,
                            pressedElevation: 0.0,
                          ),
                          trackShape: _CustomTrackShape(),
                          overlayColor: const Color(0x00000000),
                        ),
                        child: Slider(
                          value: volume.clamp(0.0, 100.0),
                          min: 0.0,
                          max: 100.0,
                          onChanged: (value) async {
                            await widget.controller.player.setVolume(value);
                            mute = false;
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 18.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionIndicator extends StatefulWidget {
  final MaterialVideoControlsThemeData data;
  final VideoController controller;
  const _PositionIndicator(
      {Key? key, required this.data, required this.controller})
      : super(key: key);

  @override
  State<_PositionIndicator> createState() => _PositionIndicatorState();
}

class _PositionIndicatorState extends State<_PositionIndicator> {
  late Duration position = widget.controller.player.state.position;
  late Duration duration = widget.controller.player.state.duration;

  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    subscriptions.addAll(
      [
        widget.controller.player.streams.position.listen((event) {
          setState(() {
            position = event;
          });
        }),
        widget.controller.player.streams.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatDuration(position, duration)} / ${formatDuration(duration, duration)}',
      style: TextStyle(
        height: 1.0,
        fontSize: 12.0,
        color: widget.data.bottomButtonBarButtonColor,
      ),
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight;
    final left = offset.dx;
    final top = offset.dy + (parentBox.size.height - height!) / 2;
    final width = parentBox.size.width;
    return Rect.fromLTWH(
      left,
      top,
      width,
      height,
    );
  }
}
