/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video_controls/media_kit_video_controls.dart'
    as media_kit_video_controls;
import 'package:media_kit_video/src/utils/wakelock.dart';

import 'package:media_kit_video/src/video_controller/video_controller.dart';
import 'package:media_kit_video/src/video_controller/platform_video_controller.dart';

import 'package:media_kit_video/src/subtitle/subtitle_view.dart';

/// {@template video}
///
/// Video
/// -----
/// [Video] widget is used to display video output.
///
/// Use [VideoController] to initialize & handle the video rendering.
///
/// **Example:**
///
/// ```dart
/// class MyScreen extends StatefulWidget {
///   const MyScreen({Key? key}) : super(key: key);
///   @override
///   State<MyScreen> createState() => MyScreenState();
/// }
///
/// class MyScreenState extends State<MyScreen> {
///   late final player = Player();
///   late final controller = VideoController(player);
///
///   @override
///   void initState() {
///     super.initState();
///     player.open(Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
///   }
///
///   @override
///   void dispose() {
///     player.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Video(
///         controller: controller,
///       ),
///     );
///   }
/// }
/// ```
///
/// {@endtemplate}
class Video extends StatefulWidget {
  /// The [VideoController] reference to control this [Video] output.
  final VideoController controller;

  /// Height of this viewport.
  final double? width;

  /// Width of this viewport.
  final double? height;

  /// Fit of the viewport.
  final BoxFit fit;

  /// Background color to fill the video background.
  final Color fill;

  /// Alignment of the viewport.
  final Alignment alignment;

  /// Preferred aspect ratio of the viewport.
  final double? aspectRatio;

  /// Filter quality of the [Texture] widget displaying the video output.
  final FilterQuality filterQuality;

  /// Video controls builder.
  final VideoControlsBuilder? controls;

  /// Whether to acquire wake lock while playing the video.
  final bool wakelock;

  /// Whether to pause the video when application enters background mode.
  final bool pauseUponEnteringBackgroundMode;

  /// The configuration for subtitles e.g. [TextStyle] & padding etc.
  final SubtitleViewConfiguration subtitleViewConfiguration;

  /// {@macro video}
  const Video({
    Key? key,
    required this.controller,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fill = const Color(0xFF000000),
    this.alignment = Alignment.center,
    this.aspectRatio,
    this.filterQuality = FilterQuality.low,
    this.controls = media_kit_video_controls.AdaptiveVideoControls,
    this.wakelock = true,
    this.pauseUponEnteringBackgroundMode = true,
    this.subtitleViewConfiguration = const SubtitleViewConfiguration(),
  }) : super(key: key);

  @override
  State<Video> createState() => VideoState();
}

class VideoState extends State<Video> with WidgetsBindingObserver {
  final GlobalKey<SubtitleViewState> _subtitleViewKey =
      GlobalKey<SubtitleViewState>();
  final Wakelock _wakelock = Wakelock();
  StreamSubscription? _playingSubscription;

  // Public API:

  bool isFullscreen() {
    return media_kit_video_controls.isFullscreen(context);
  }

  Future<void> enterFullscreen() {
    return media_kit_video_controls.enterFullscreen(context);
  }

  Future<void> exitFullscreen() {
    return media_kit_video_controls.exitFullscreen(context);
  }

  Future<void> toggleFullscreen() {
    return media_kit_video_controls.toggleFullscreen(context);
  }

  void setSubtitleViewPadding(
    EdgeInsets padding, {
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _subtitleViewKey.currentState?.setPadding(
      padding,
      duration: duration,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.pauseUponEnteringBackgroundMode) {
      if ([
        AppLifecycleState.paused,
        AppLifecycleState.inactive,
        AppLifecycleState.detached,
      ].contains(state)) {
        widget.controller.player.pause();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.wakelock) {
      if (widget.controller.player.state.playing) {
        _wakelock.enable();
      }
      _playingSubscription = widget.controller.player.stream.playing.listen(
        (playing) {
          if (playing) {
            _wakelock.enable();
          } else {
            _wakelock.disable();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wakelock.disable();
    _playingSubscription?.cancel();
    super.dispose();
  }

  void refreshView() {}

  @override
  Widget build(BuildContext context) {
    final controls = widget.controls;
    final controller = widget.controller;
    final aspectRatio = widget.aspectRatio;
    final subtitleViewConfiguration = widget.subtitleViewConfiguration;
    return Container(
      clipBehavior: Clip.none,
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: widget.fill,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              alignment: widget.alignment,
              fit: widget.fit,
              child: ValueListenableBuilder<PlatformVideoController?>(
                valueListenable: controller.notifier,
                builder: (context, notifier, _) => notifier == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<int?>(
                        valueListenable: notifier.id,
                        builder: (context, id, _) {
                          return ValueListenableBuilder<Rect?>(
                            valueListenable: notifier.rect,
                            builder: (context, rect, _) {
                              if (id != null && rect != null) {
                                return SizedBox(
                                  // Apply aspect ratio if provided.
                                  width: aspectRatio == null
                                      ? rect.width
                                      : rect.height * aspectRatio,
                                  height: rect.height,
                                  child: Stack(
                                    children: [
                                      const SizedBox(),
                                      Positioned.fill(
                                        child: Texture(
                                          textureId: id,
                                          filterQuality: widget.filterQuality,
                                        ),
                                      ),
                                      // Keep the |Texture| hidden before the first frame renders. In native implementation, if no default frame size is passed (through VideoController), a starting 1 pixel sized texture/surface is created to initialize the render context & check for H/W support.
                                      // This is then resized based on the video dimensions & accordingly texture ID, texture, EGLDisplay, EGLSurface etc. (depending upon platform) are also changed. Just don't show that 1 pixel texture to the UI.
                                      // NOTE: Unmounting |Texture| causes the |MarkTextureFrameAvailable| to not do anything on GNU/Linux.
                                      if (rect.width <= 1.0 &&
                                          rect.height <= 1.0)
                                        Positioned.fill(
                                          child: Container(
                                            color: widget.fill,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
              ),
            ),
          ),
          if (subtitleViewConfiguration.visible &&
              !(controller.player.platform?.configuration.libass ?? false))
            Positioned.fill(
              child: SubtitleView(
                controller: controller,
                key: _subtitleViewKey,
                configuration: subtitleViewConfiguration,
              ),
            ),
          if (controls != null)
            Positioned.fill(
              child: controls.call(this),
            ),
        ],
      ),
    );
  }
}

typedef VideoControlsBuilder = Widget Function(VideoState state);
