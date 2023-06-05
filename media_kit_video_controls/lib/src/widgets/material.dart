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
  final data = MaterialVideoControlsTheme.maybeOf(context)?.data;
  final Widget child;
  if (data == null) {
    child = const MaterialVideoControlsTheme(
      data: MaterialVideoControlsThemeData(),
      child: _MaterialVideoControls(),
    );
  } else {
    child = const _MaterialVideoControls();
  }
  return VideoControllerInheritedWidget(controller: controller, child: child);
}

/// [MaterialVideoControlsThemeData] available in this [context].
MaterialVideoControlsThemeData theme(BuildContext context) =>
    MaterialVideoControlsTheme.of(context).data;

/// {@template material_video_controlstheme_data}
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

  /// Buttons to be displayed in the bottom button bar.
  final List<Widget> bottombuttonBar;

  /// Margin around the bottom button bar.
  final EdgeInsets bottomButtonBarMargin;

  /// Height of the bottom button bar.
  final double bottomButtonBarHeight;

  /// Size of the bottom button bar buttons.
  final double bottomButtonBarButtonSize;

  /// Color of the bottom button bar buttons.
  final Color bottomButtonBarButtonColor;

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
    this.bottombuttonBar = const [
      MaterialSkipPreviousButton(),
      MaterialPlayOrPauseButton(),
      MaterialSkipNextButton(),
      MaterialVolumeButton(),
      MaterialPositionIndicator(),
      Spacer(),
    ],
    this.bottomButtonBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.bottomButtonBarHeight = 56.0,
    this.bottomButtonBarButtonSize = 28.0,
    this.bottomButtonBarButtonColor = const Color(0xFFFFFFFF),
    this.volumeBarColor = const Color(0x3DFFFFFF),
    this.volumeBarActiveColor = const Color(0xFFFFFFFF),
    this.volumeBarThumbSize = 12.0,
    this.volumeBarThumbColor = const Color(0xFFFFFFFF),
    this.volumeBarTransitionDuration = const Duration(milliseconds: 150),
    this.automaticallyImplySkipNextButton = true,
    this.automaticallyImplySkipPreviousButton = true,
  });
}

/// {@template material_video_controlstheme}
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
      identical(data, oldWidget.data);
}

/// {@macro material_video_controls}
class _MaterialVideoControls extends StatefulWidget {
  const _MaterialVideoControls();

  @override
  State<_MaterialVideoControls> createState() => _MaterialVideoControlsState();
}

/// {@macro material_video_controls}
class _MaterialVideoControlsState extends State<_MaterialVideoControls> {
  bool visible = false;

  Timer? _timer;

  late var playlist = controller(context).player.state.playlist;

  final List<StreamSubscription> subscriptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty) {
      subscriptions.addAll(
        [
          controller(context).player.streams.playlist.listen(
            (event) {
              setState(() {
                playlist = event;
              });
            },
          ),
        ],
      );
    }
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
    _timer = Timer(theme(context).controlsHoverDuration, () {
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
    _timer = Timer(theme(context).controlsHoverDuration, () {
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
        duration: theme(context).controlsTransitionDuration,
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
                  child: const MaterialSeekBar(),
                ),
                Container(
                  height: theme(context).bottomButtonBarHeight,
                  margin: theme(context).bottomButtonBarMargin,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: theme(context).bottombuttonBar,
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

class MaterialSeekBar extends StatefulWidget {
  const MaterialSeekBar({
    Key? key,
  }) : super(key: key);

  @override
  MaterialSeekBarState createState() => MaterialSeekBarState();
}

class MaterialSeekBarState extends State<MaterialSeekBar> {
  bool hover = false;
  bool click = false;
  double slider = 0.0;

  late bool playing = controller(context).player.state.playing;
  late Duration position = controller(context).player.state.position;
  late Duration duration = controller(context).player.state.duration;
  late Duration buffer = controller(context).player.state.buffer;

  final List<StreamSubscription> subscriptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty) {
      subscriptions.addAll(
        [
          controller(context).player.streams.playing.listen((event) {
            setState(() {
              playing = event;
            });
          }),
          controller(context).player.streams.completed.listen((event) {
            setState(() {
              position = Duration.zero;
            });
          }),
          controller(context).player.streams.position.listen((event) {
            setState(() {
              if (!click) position = event;
            });
          }),
          controller(context).player.streams.duration.listen((event) {
            setState(() {
              duration = event;
            });
          }),
          controller(context).player.streams.buffer.listen((event) {
            setState(() {
              buffer = event;
            });
          }),
        ],
      );
    }
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
    controller(context).player.seek(duration * slider);
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
      margin: theme(context).seekBarMargin,
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
              height: theme(context).seekBarContainerHeight,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedContainer(
                    width: constraints.maxWidth,
                    height: hover
                        ? theme(context).seekBarHoverHeight
                        : theme(context).seekBarHeight,
                    alignment: Alignment.centerLeft,
                    duration: theme(context).seekBarThumbTransitionDuration,
                    color: theme(context).seekBarColor,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          width: constraints.maxWidth * slider,
                          color: theme(context).seekBarHoverColor,
                        ),
                        Container(
                          width: constraints.maxWidth * bufferPercent,
                          color: theme(context).seekBarBufferColor,
                        ),
                        Container(
                          width: click
                              ? constraints.maxWidth * slider
                              : constraints.maxWidth * positionPercent,
                          color: theme(context).seekBarPositionColor,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: click
                        ? (constraints.maxWidth -
                                theme(context).seekBarThumbSize / 2) *
                            slider
                        : (constraints.maxWidth -
                                theme(context).seekBarThumbSize / 2) *
                            positionPercent,
                    child: AnimatedContainer(
                      width: hover || click
                          ? theme(context).seekBarThumbSize
                          : 0.0,
                      height: hover || click
                          ? theme(context).seekBarThumbSize
                          : 0.0,
                      duration: theme(context).seekBarThumbTransitionDuration,
                      decoration: BoxDecoration(
                        color: theme(context).seekBarThumbColor,
                        borderRadius: BorderRadius.circular(
                          theme(context).seekBarThumbSize / 2,
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

// BUTTON: PLAY/PAUSE

class MaterialPlayOrPauseButton extends StatefulWidget {
  const MaterialPlayOrPauseButton({super.key});

  @override
  MaterialPlayOrPauseButtonState createState() =>
      MaterialPlayOrPauseButtonState();
}

class MaterialPlayOrPauseButtonState extends State<MaterialPlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    value: controller(context).player.state.playing ? 1 : 0,
    duration: const Duration(milliseconds: 200),
  );

  StreamSubscription<bool>? subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscription ??= controller(context).player.streams.playing.listen((event) {
      if (event) {
        animation.forward();
      } else {
        animation.reverse();
      }
    });
  }

  @override
  void dispose() {
    animation.dispose();
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: controller(context).player.playOrPause,
      iconSize: theme(context).bottomButtonBarButtonSize,
      color: theme(context).bottomButtonBarButtonColor,
      icon: AnimatedIcon(
        progress: animation,
        icon: AnimatedIcons.play_pause,
        size: theme(context).bottomButtonBarButtonSize,
        color: theme(context).bottomButtonBarButtonColor,
      ),
    );
  }
}

// BUTTON: SKIP NEXT

class MaterialSkipNextButton extends StatelessWidget {
  const MaterialSkipNextButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!theme(context).automaticallyImplySkipNextButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            theme(context).automaticallyImplySkipNextButton)) {
      return IconButton(
        onPressed: controller(context).player.next,
        iconSize: theme(context).bottomButtonBarButtonSize,
        color: theme(context).bottomButtonBarButtonColor,
        icon: const Icon(Icons.skip_previous),
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: SKIP PREVIOUS

class MaterialSkipPreviousButton extends StatelessWidget {
  const MaterialSkipPreviousButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!theme(context).automaticallyImplySkipPreviousButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            theme(context).automaticallyImplySkipPreviousButton)) {
      return IconButton(
        onPressed: controller(context).player.previous,
        iconSize: theme(context).bottomButtonBarButtonSize,
        color: theme(context).bottomButtonBarButtonColor,
        icon: const Icon(Icons.skip_previous),
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: VOLUME

class MaterialVolumeButton extends StatefulWidget {
  const MaterialVolumeButton({super.key});

  @override
  MaterialVolumeButtonState createState() => MaterialVolumeButtonState();
}

class MaterialVolumeButtonState extends State<MaterialVolumeButton>
    with SingleTickerProviderStateMixin {
  late double volume = controller(context).player.state.volume;

  StreamSubscription<double>? subscription;

  bool hover = false;

  bool mute = false;
  double _volume = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscription ??= controller(context).player.streams.volume.listen((event) {
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
                await controller(context).player.setVolume(_volume);
              } else {
                _volume = volume;
                await controller(context).player.setVolume(0.0);
              }
              mute = !mute;
              setState(() {});
            },
            iconSize: theme(context).bottomButtonBarButtonSize * 0.8,
            color: theme(context).bottomButtonBarButtonColor,
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
            duration: theme(context).volumeBarTransitionDuration,
            child: AnimatedContainer(
              width: hover ? (12.0 + 52.0 + 18.0) : 12.0,
              duration: theme(context).volumeBarTransitionDuration,
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
                          inactiveTrackColor: theme(context).volumeBarColor,
                          activeTrackColor: theme(context).volumeBarActiveColor,
                          thumbColor: theme(context).volumeBarThumbColor,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius:
                                theme(context).volumeBarThumbSize / 2,
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
                            await controller(context).player.setVolume(value);
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

// POSITION INDICATOR

class MaterialPositionIndicator extends StatefulWidget {
  const MaterialPositionIndicator({super.key});

  @override
  MaterialPositionIndicatorState createState() =>
      MaterialPositionIndicatorState();
}

class MaterialPositionIndicatorState extends State<MaterialPositionIndicator> {
  late Duration position = controller(context).player.state.position;
  late Duration duration = controller(context).player.state.duration;

  final List<StreamSubscription> subscriptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty) {
      subscriptions.addAll(
        [
          controller(context).player.streams.position.listen((event) {
            setState(() {
              position = event;
            });
          }),
          controller(context).player.streams.duration.listen((event) {
            setState(() {
              duration = event;
            });
          }),
        ],
      );
    }
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
      '${position.label(reference: duration)} / ${duration.label(reference: duration)}',
      style: TextStyle(
        height: 1.0,
        fontSize: 12.0,
        color: theme(context).bottomButtonBarButtonColor,
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
