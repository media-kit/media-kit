/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'package:media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:media_kit_video_controls/src/controls/methods/video_controller.dart';
import 'package:media_kit_video_controls/src/controls/widgets/fullscreen_inherited_widget.dart';
import 'package:media_kit_video_controls/src/controls/widgets/video_controller_inherited_widget.dart';

/// {@template material_video_controls}
///
/// [Video] controls which use Material design.
///
/// {@endtemplate}
Widget MaterialVideoControls(
  BuildContext context,
  VideoController controller,
) {
  final theme = MaterialVideoControlsTheme.maybeOf(context);
  final Widget child;
  if (theme == null) {
    child = const MaterialVideoControlsTheme(
      normal: kDefaultMaterialVideoControlsThemeData,
      fullscreen: kDefaultMaterialVideoControlsThemeDataFullscreen,
      child: _MaterialVideoControls(),
    );
  } else {
    child = const _MaterialVideoControls();
  }
  return VideoControllerInheritedWidget(controller: controller, child: child);
}

/// [MaterialVideoControlsThemeData] available in this [context].
MaterialVideoControlsThemeData _theme(BuildContext context) =>
    FullscreenInheritedWidget.maybeOf(context) == null
        ? MaterialVideoControlsTheme.of(context).normal
        : MaterialVideoControlsTheme.of(context).fullscreen;

/// Default [MaterialVideoControlsThemeData].
const kDefaultMaterialVideoControlsThemeData = MaterialVideoControlsThemeData();

/// Default [MaterialVideoControlsThemeData] for fullscreen.
const kDefaultMaterialVideoControlsThemeDataFullscreen =
    MaterialVideoControlsThemeData(
  displaySeekBar: true,
  automaticallyImplySkipNextButton: true,
  automaticallyImplySkipPreviousButton: true,
  brightnessGesture: true,
  volumeGesture: true,
  seekGesture: true,
  seekOnDoubleTap: true,
  controlsHoverDuration: Duration(seconds: 3),
  controlsTransitionDuration: Duration(milliseconds: 300),
  primaryButtonBar: [
    Spacer(flex: 2),
    MaterialSkipPreviousButton(),
    Spacer(),
    MaterialPlayOrPauseButton(iconSize: 56.0),
    Spacer(),
    MaterialSkipNextButton(),
    Spacer(flex: 2),
  ],
  topButtonBar: [],
  bottomButtonBar: [
    MaterialPositionIndicator(),
    Spacer(),
    MaterialFullscreenButton(),
  ],
  buttonBarMargin: EdgeInsets.only(
    // Don't ask me why "left" & "right" are not equal.
    // Yeah... It's driving me crazy too.
    left: 16.0,
    right: 8.0,
    bottom: 36.0,
  ),
  buttonBarHeight: 56.0,
  buttonBarButtonSize: 24.0,
  buttonBarButtonColor: Color(0xFFFFFFFF),
  seekBarMargin: EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    bottom: 36.0,
  ),
  seekBarHeight: 2.4,
  seekBarContainerHeight: 36.0,
  seekBarColor: Color(0x3DFFFFFF),
  seekBarPositionColor: Color(0xFFFF0000),
  seekBarBufferColor: Color(0x3DFFFFFF),
  seekBarThumbSize: 12.8,
  seekBarThumbColor: Color(0xFFFF0000),
);

/// {@template material_video_controlstheme_data}
///
/// Theming related data for [MaterialVideoControls]. These values are used to theme the descendant [MaterialVideoControls].
///
/// {@endtemplate}
class MaterialVideoControlsThemeData {
  // BEHAVIOR

  /// Whether to display seek bar.
  final bool displaySeekBar;

  /// Whether a skip next button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipNextButton;

  /// Whether a skip previous button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipPreviousButton;

  /// Whether to modify screen brightness on vertical drag gesture on the left side of the screen.
  final bool brightnessGesture;

  /// Whether to modify volume on vertical drag gesture on the right side of the screen.
  final bool volumeGesture;

  /// Whether to modify playback position on horizontal drag gesture on the screen.
  final bool seekGesture;

  /// Whether to enable double tap to seek on left or right side of the screen.
  final bool seekOnDoubleTap;

  // GENERIC

  /// [Duration] after which the controls will be hidden when there is no mouse movement.
  final Duration controlsHoverDuration;

  /// [Duration] for which the controls will be animated when shown or hidden.
  final Duration controlsTransitionDuration;

  // BUTTON BAR

  /// Buttons to be displayed in the primary button bar.
  final List<Widget> primaryButtonBar;

  /// Buttons to be displayed in the top button bar.
  final List<Widget> topButtonBar;

  /// Buttons to be displayed in the bottom button bar.
  final List<Widget> bottomButtonBar;

  /// Margin around the button bar.
  final EdgeInsets buttonBarMargin;

  /// Height of the button bar.
  final double buttonBarHeight;

  /// Size of the button bar buttons.
  final double buttonBarButtonSize;

  /// Color of the button bar buttons.
  final Color buttonBarButtonColor;

  // SEEK BAR

  /// Margin around the seek bar.
  final EdgeInsets seekBarMargin;

  /// Height of the seek bar.
  final double seekBarHeight;

  /// Height of the seek bar [Container].
  final double seekBarContainerHeight;

  /// [Color] of the seek bar.
  final Color seekBarColor;

  /// [Color] of the playback position section in the seek bar.
  final Color seekBarPositionColor;

  /// [Color] of the playback buffer section in the seek bar.
  final Color seekBarBufferColor;

  /// Size of the seek bar thumb.
  final double seekBarThumbSize;

  /// [Color] of the seek bar thumb.
  final Color seekBarThumbColor;

  /// {@macro material_video_controlstheme_data}
  const MaterialVideoControlsThemeData({
    this.displaySeekBar = true,
    this.automaticallyImplySkipNextButton = true,
    this.automaticallyImplySkipPreviousButton = true,
    this.brightnessGesture = false,
    this.volumeGesture = false,
    this.seekGesture = false,
    this.seekOnDoubleTap = false,
    this.controlsHoverDuration = const Duration(seconds: 3),
    this.controlsTransitionDuration = const Duration(milliseconds: 300),
    this.primaryButtonBar = const [
      Spacer(flex: 2),
      MaterialSkipPreviousButton(),
      Spacer(),
      MaterialPlayOrPauseButton(iconSize: 56.0),
      Spacer(),
      MaterialSkipNextButton(),
      Spacer(flex: 2),
    ],
    this.topButtonBar = const [],
    this.bottomButtonBar = const [
      MaterialPositionIndicator(),
      Spacer(),
      MaterialFullscreenButton(),
    ],
    this.buttonBarMargin = const EdgeInsets.only(left: 16.0, right: 8.0),
    this.buttonBarHeight = 56.0,
    this.buttonBarButtonSize = 24.0,
    this.buttonBarButtonColor = const Color(0xFFFFFFFF),
    this.seekBarMargin = EdgeInsets.zero,
    this.seekBarHeight = 2.4,
    this.seekBarContainerHeight = 36.0,
    this.seekBarColor = const Color(0x3DFFFFFF),
    this.seekBarPositionColor = const Color(0xFFFF0000),
    this.seekBarBufferColor = const Color(0x3DFFFFFF),
    this.seekBarThumbSize = 12.8,
    this.seekBarThumbColor = const Color(0xFFFF0000),
  });
}

/// {@template material_video_controls_theme}
///
/// Inherited widget which provides [MaterialVideoControlsThemeData] to descendant widgets.
///
/// {@endtemplate}
class MaterialVideoControlsTheme extends InheritedWidget {
  final MaterialVideoControlsThemeData normal;
  final MaterialVideoControlsThemeData fullscreen;
  const MaterialVideoControlsTheme({
    super.key,
    required this.normal,
    required this.fullscreen,
    required super.child,
  });

  static MaterialVideoControlsTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MaterialVideoControlsTheme>();
  }

  static MaterialVideoControlsTheme of(BuildContext context) {
    final MaterialVideoControlsTheme? result = maybeOf(context);
    assert(
      result != null,
      'No [MaterialVideoControlsTheme] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(MaterialVideoControlsTheme oldWidget) =>
      identical(normal, oldWidget.normal) &&
      identical(fullscreen, oldWidget.fullscreen);
}

/// {@macro material_video_controls}
class _MaterialVideoControls extends StatefulWidget {
  const _MaterialVideoControls();

  @override
  State<_MaterialVideoControls> createState() => _MaterialVideoControlsState();
}

/// {@macro material_video_controls}
class _MaterialVideoControlsState extends State<_MaterialVideoControls> {
  bool mount = false;
  bool visible = false;

  Timer? _timer;

  double _brightnessValue = 0.0;
  bool _brightnessIndicator = false;
  Timer? _brightnessTimer;

  double _volumeValue = 0.0;
  bool _volumeIndicator = false;
  Timer? _volumeTimer;
  bool _volumeInterceptEventChannel = false;

  late /* private */ var playlist = controller(context).player.state.playlist;

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
    // --------------------------------------------------
    // package:screen_brightness
    Future.microtask(() async {
      try {
        ScreenBrightness().resetScreenBrightness();
      } catch (_) {}
    });
    // --------------------------------------------------
    super.dispose();
  }

  void onTap() {
    if (!visible) {
      setState(() {
        mount = true;
        visible = true;
      });
      _timer?.cancel();
      _timer = Timer(_theme(context).controlsHoverDuration, () {
        if (mounted) {
          setState(() {
            visible = false;
          });
        }
      });
    } else {
      setState(() {
        visible = false;
      });
      _timer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    // --------------------------------------------------
    // package:volume_controller
    Future.microtask(() async {
      try {
        VolumeController().showSystemUI = false;
        _volumeValue = await VolumeController().getVolume();
        VolumeController().listener((value) {
          if (mounted && !_volumeInterceptEventChannel) {
            setState(() {
              _volumeValue = value;
            });
          }
        });
      } catch (_) {}
    });
    // --------------------------------------------------
    // --------------------------------------------------
    // package:screen_brightness
    Future.microtask(() async {
      try {
        _brightnessValue = await ScreenBrightness().current;
        ScreenBrightness().onCurrentBrightnessChanged.listen((value) {
          if (mounted) {
            setState(() {
              _brightnessValue = value;
            });
          }
        });
      } catch (_) {}
    });
    // --------------------------------------------------
  }

  void setVolume(double value) {
    // --------------------------------------------------
    // package:volume_controller
    VolumeController().setVolume(value);
    setState(() {
      _volumeValue = value;
      _volumeIndicator = true;
      _volumeInterceptEventChannel = true;
    });
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _volumeIndicator = false;
          _volumeInterceptEventChannel = false;
        });
      }
    });
    // --------------------------------------------------
  }

  void setBrightness(double value) {
    // --------------------------------------------------
    // package:screen_brightness
    ScreenBrightness().setScreenBrightness(value);
    setState(() {
      _brightnessIndicator = true;
    });
    _brightnessTimer?.cancel();
    _brightnessTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _brightnessIndicator = false;
        });
      }
    });
    // --------------------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    Widget wrapInSafeAreaIfRequired({required Widget child}) =>
        isFullscreen(context) ? SafeArea(child: child) : child;
    return Theme(
      data: ThemeData(
        focusColor: const Color(0x00000000),
        hoverColor: const Color(0x00000000),
        splashColor: const Color(0x00000000),
        highlightColor: const Color(0x00000000),
      ),
      child: Focus(
        autofocus: true,
        child: wrapInSafeAreaIfRequired(
          child: Material(
            elevation: 0.0,
            borderOnForeground: false,
            animationDuration: Duration.zero,
            color: const Color(0x00000000),
            shadowColor: const Color(0x00000000),
            surfaceTintColor: const Color(0x00000000),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Volume Indicator.
                AnimatedOpacity(
                  curve: Curves.easeInOut,
                  opacity: !mount && _volumeIndicator ? 1.0 : 0.0,
                  duration: _theme(context).controlsTransitionDuration,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x88000000),
                      borderRadius: BorderRadius.circular(64.0),
                    ),
                    height: 52.0,
                    width: 108.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 52.0,
                          width: 42.0,
                          alignment: Alignment.centerRight,
                          child: Icon(
                            _volumeValue == 0.0
                                ? Icons.volume_off
                                : _volumeValue < 0.5
                                    ? Icons.volume_down
                                    : Icons.volume_up,
                            color: const Color(0xFFFFFFFF),
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            '${(_volumeValue * 100.0).round()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                    ),
                  ),
                ),
                // Brightness Indicator.
                AnimatedOpacity(
                  curve: Curves.easeInOut,
                  opacity: !mount && _brightnessIndicator ? 1.0 : 0.0,
                  duration: _theme(context).controlsTransitionDuration,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x88000000),
                      borderRadius: BorderRadius.circular(64.0),
                    ),
                    height: 52.0,
                    width: 108.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 52.0,
                          width: 42.0,
                          alignment: Alignment.centerRight,
                          child: Icon(
                            _brightnessValue < 1.0 / 3.0
                                ? Icons.brightness_low
                                : _brightnessValue < 2.0 / 3.0
                                    ? Icons.brightness_medium
                                    : Icons.brightness_high,
                            color: const Color(0xFFFFFFFF),
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            '${(_brightnessValue * 100.0).round()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                    ),
                  ),
                ),
                // Controls:
                AnimatedOpacity(
                  curve: Curves.easeInOut,
                  opacity: visible ? 1.0 : 0.0,
                  duration: _theme(context).controlsTransitionDuration,
                  onEnd: () {
                    setState(() {
                      if (!visible) {
                        mount = false;
                      }
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: const Color(0x66000000),
                        ),
                      ),
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onTap,
                                onVerticalDragUpdate: !mount &&
                                        _theme(context).brightnessGesture
                                    ? (e) async {
                                        final delta = e.primaryDelta ?? 0.0;
                                        final brightness =
                                            _brightnessValue - delta / 100.0;
                                        final result =
                                            brightness.clamp(0.0, 1.0);
                                        setBrightness(result);
                                      }
                                    : null,
                                child: Container(
                                  color: const Color(0x00000000),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: onTap,
                                child: Container(
                                  color: const Color(0x00000000),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: onTap,
                                onVerticalDragUpdate: !mount &&
                                        _theme(context).volumeGesture
                                    ? (e) async {
                                        final delta = e.primaryDelta ?? 0.0;
                                        final volume =
                                            _volumeValue - delta / 100.0;
                                        final result = volume.clamp(0.0, 1.0);
                                        setVolume(result);
                                      }
                                    : null,
                                child: Container(
                                  color: const Color(0x00000000),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mount) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: _theme(context).buttonBarHeight,
                              margin: _theme(context).buttonBarMargin,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: _theme(context).topButtonBar,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _theme(context).primaryButtonBar,
                                ),
                              ),
                            ),
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                if (_theme(context).displaySeekBar)
                                  Transform.translate(
                                    offset: Offset.zero,
                                    child: const MaterialSeekBar(),
                                  ),
                                Container(
                                  height: _theme(context).buttonBarHeight,
                                  margin: _theme(context).buttonBarMargin,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: _theme(context).bottomButtonBar,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SEEK BAR

/// Material design seek bar.
class MaterialSeekBar extends StatefulWidget {
  const MaterialSeekBar({
    Key? key,
  }) : super(key: key);

  @override
  MaterialSeekBarState createState() => MaterialSeekBarState();
}

class MaterialSeekBarState extends State<MaterialSeekBar> {
  bool tapped = false;
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
              if (!tapped) {
                position = event;
              }
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
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onPointerDown() {
    setState(() {
      tapped = true;
    });
  }

  void onPointerUp() {
    setState(() {
      tapped = false;
    });
    controller(context).player.seek(duration * slider);
  }

  void onHover(PointerHoverEvent e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
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
      margin: _theme(context).seekBarMargin,
      child: LayoutBuilder(
        builder: (context, constraints) => MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (e) => onHover(e, constraints),
          child: Listener(
            onPointerMove: (e) => onPointerMove(e, constraints),
            onPointerDown: (e) => onPointerDown(),
            onPointerUp: (e) => onPointerUp(),
            child: Container(
              color: Colors.transparent,
              width: constraints.maxWidth,
              height: _theme(context).seekBarContainerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomLeft,
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: _theme(context).seekBarHeight,
                    alignment: Alignment.bottomLeft,
                    color: _theme(context).seekBarColor,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomLeft,
                      children: [
                        Container(
                          width: constraints.maxWidth * bufferPercent,
                          color: _theme(context).seekBarBufferColor,
                        ),
                        Container(
                          width: tapped
                              ? constraints.maxWidth * slider
                              : constraints.maxWidth * positionPercent,
                          color: _theme(context).seekBarPositionColor,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: tapped
                        ? (constraints.maxWidth -
                                _theme(context).seekBarThumbSize / 2) *
                            slider
                        : (constraints.maxWidth -
                                _theme(context).seekBarThumbSize / 2) *
                            positionPercent,
                    bottom: -1.0 * _theme(context).seekBarThumbSize / 2 +
                        _theme(context).seekBarHeight / 2,
                    child: Container(
                      width: _theme(context).seekBarThumbSize,
                      height: _theme(context).seekBarThumbSize,
                      decoration: BoxDecoration(
                        color: _theme(context).seekBarThumbColor,
                        borderRadius: BorderRadius.circular(
                          _theme(context).seekBarThumbSize / 2,
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

/// A material design play/pause button.
class MaterialPlayOrPauseButton extends StatefulWidget {
  /// Overriden icon size for [MaterialSkipPreviousButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipPreviousButton].
  final Color? iconColor;

  const MaterialPlayOrPauseButton({
    super.key,
    this.iconSize,
    this.iconColor,
  });

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
      iconSize: widget.iconSize ?? _theme(context).buttonBarButtonSize,
      color: widget.iconColor ?? _theme(context).buttonBarButtonColor,
      icon: AnimatedIcon(
        progress: animation,
        icon: AnimatedIcons.play_pause,
        size: widget.iconSize ?? _theme(context).buttonBarButtonSize,
        color: widget.iconColor ?? _theme(context).buttonBarButtonColor,
      ),
    );
  }
}

// BUTTON: SKIP NEXT

/// Material design skip next button.
class MaterialSkipNextButton extends StatelessWidget {
  /// Icon for [MaterialSkipNextButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialSkipNextButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipNextButton].
  final Color? iconColor;

  const MaterialSkipNextButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_theme(context).automaticallyImplySkipNextButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            _theme(context).automaticallyImplySkipNextButton)) {
      return IconButton(
        onPressed: controller(context).player.next,
        icon: icon ?? const Icon(Icons.skip_next),
        iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
        color: iconColor ?? _theme(context).buttonBarButtonColor,
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: SKIP PREVIOUS

/// Material design skip previous button.
class MaterialSkipPreviousButton extends StatelessWidget {
  /// Icon for [MaterialSkipPreviousButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialSkipPreviousButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipPreviousButton].
  final Color? iconColor;

  const MaterialSkipPreviousButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_theme(context).automaticallyImplySkipPreviousButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            _theme(context).automaticallyImplySkipPreviousButton)) {
      return IconButton(
        onPressed: controller(context).player.previous,
        icon: icon ?? const Icon(Icons.skip_previous),
        iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
        color: iconColor ?? _theme(context).buttonBarButtonColor,
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: FULL SCREEN

/// Material design fullscreen button.
class MaterialFullscreenButton extends StatelessWidget {
  /// Icon for [MaterialFullscreenButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialFullscreenButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialFullscreenButton].
  final Color? iconColor;

  const MaterialFullscreenButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => toggleFullscreen(controller(context), context),
      icon: icon ??
          (isFullscreen(context)
              ? const Icon(Icons.fullscreen_exit)
              : const Icon(Icons.fullscreen)),
      iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
      color: iconColor ?? _theme(context).buttonBarButtonColor,
    );
  }
}

// BUTTON: CUSTOM

/// Material design fullscreen button.
class MaterialCustomButton extends StatelessWidget {
  /// Icon for [MaterialCustomButton].
  final Widget? icon;

  /// Icon size for [MaterialCustomButton].
  final double? iconSize;

  /// Icon color for [MaterialCustomButton].
  final Color? iconColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  final VoidCallback onPressed;

  const MaterialCustomButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: icon ?? const Icon(Icons.fullscreen),
      padding: EdgeInsets.zero,
      iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
      color: iconColor ?? _theme(context).buttonBarButtonColor,
    );
  }
}

// POSITION INDICATOR

/// Material design position indicator.
class MaterialPositionIndicator extends StatefulWidget {
  /// Overriden [TextStyle] for the [MaterialPositionIndicator].
  final TextStyle? style;
  const MaterialPositionIndicator({super.key, this.style});

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
      style: widget.style ??
          TextStyle(
            height: 1.0,
            fontSize: 12.0,
            color: _theme(context).buttonBarButtonColor,
          ),
    );
  }
}
