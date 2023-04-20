import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video_controls/widgets/animated_play_pause.dart';
import 'package:media_kit_video_controls/widgets/center_play_button.dart';
import 'package:media_kit_video_controls/widgets/media_kit_player.dart';
import 'package:media_kit_video_controls/widgets/media_kit_progress_colors.dart';
import 'package:media_kit_video_controls/widgets/helpers/utils.dart';
import 'package:media_kit_video_controls/widgets/material/material_progress_bar.dart';
import 'package:media_kit_video_controls/widgets/material/widgets/options_dialog.dart';
import 'package:media_kit_video_controls/widgets/material/widgets/playback_speed_dialog.dart';
import 'package:media_kit_video_controls/widgets/models/option_item.dart';
import 'package:media_kit_video_controls/widgets/models/subtitle_model.dart';
import 'package:media_kit_video_controls/widgets/notifiers/index.dart';
import 'package:flutter/material.dart';

class MaterialDesktopControls extends StatefulWidget {
  const MaterialDesktopControls({
    this.showPlayButton = true,
    Key? key,
  }) : super(key: key);

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _MaterialDesktopControlsState();
  }
}

class _MaterialDesktopControlsState extends State<MaterialDesktopControls>
    with SingleTickerProviderStateMixin {

  PlayerNotifier? _notifier;

  // We know that _notifier is set in didChangeDependencies
  PlayerNotifier get notifier => _notifier!;

  late PlayerState _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late Player controller;
  MediaKitController? _mediaKitController;

  // We know that _mediaKitController is set in didChangeDependencies
  MediaKitController get mediaKitController => _mediaKitController!;

  StreamSubscription? buffering;

  StreamSubscription? volume;

  @override
  Widget build(BuildContext context) {
    // if (_latestValue.hasError) {
    //   return mediaKitController.errorBuilder?.call(
    //         context,
    //         mediaKitController.player.value.errorDescription!,
    //       ) ??
    //       const Center(
    //         child: Icon(
    //           Icons.error,
    //           color: Colors.white,
    //           size: 42,
    //         ),
    //       );
    // }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (_displayBufferingIndicator)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                _buildHitArea(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                        0.0,
                        notifier.hideStuff ? barHeight * 0.8 : 0.0,
                      ),
                      child: _buildSubtitles(
                          context, mediaKitController.subtitle!),
                    ),
                  _buildBottomBar(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    buffering?.cancel();
    volume?.cancel();
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _mediaKitController;
    _mediaKitController = MediaKitController.of(context);
    controller = mediaKitController.player;

    if (oldController != mediaKitController) {
      _dispose();
      _initialize();
    }

    final oldPlayerNotifier = _notifier;
    _notifier = PlayerNotifier.of(context);

    if (oldPlayerNotifier != notifier) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }

  Widget _buildSubtitleToggle({IconData? icon, bool isPadded = false}) {
    return IconButton(
      padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
      icon: Icon(icon, color: _subtitleOn ? Colors.white : Colors.grey[700]),
      onPressed: _onSubtitleTap,
    );
  }

  Widget _buildOptionsButton({
    IconData? icon,
    bool isPadded = false,
  }) {
    final options = <OptionItem>[
      OptionItem(
        onTap: () async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title: mediaKitController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      )
    ];

    if (mediaKitController.additionalOptions != null &&
        mediaKitController.additionalOptions!(context).isNotEmpty) {
      options.addAll(mediaKitController.additionalOptions!(context));
    }

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
        onPressed: () async {
          _hideTimer?.cancel();

          if (mediaKitController.optionsBuilder != null) {
            await mediaKitController.optionsBuilder!(context, options);
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: mediaKitController.useRootNavigator,
              builder: (context) => OptionsDialog(
                options: options,
                cancelButtonText:
                    mediaKitController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (_latestValue.playing) {
            _startHideTimer();
          }
        },
        icon: Icon(
          icon ?? Icons.more_vert,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (mediaKitController.subtitleBuilder != null) {
      return mediaKitController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (mediaKitController.isFullScreen ? 20.0 : 0),
        padding: EdgeInsets.only(
            bottom: mediaKitController.isFullScreen ? 10.0 : 15),
        child: SafeArea(
          bottom: mediaKitController.isFullScreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            verticalDirection: VerticalDirection.up,
            children: [
              Flexible(
                child: Row(
                  children: <Widget>[
                    _buildPlayPause(controller),
                    _buildMuteButton(controller),
                    if (mediaKitController.isLive)
                      const Expanded(child: Text('LIVE'))
                    else
                      _buildPosition(iconColor),
                    const Spacer(),
                    if (mediaKitController.showControls &&
                        mediaKitController.subtitle != null &&
                        mediaKitController.subtitle!.isNotEmpty)
                      _buildSubtitleToggle(icon: Icons.subtitles),
                    if (mediaKitController.showOptions)
                      _buildOptionsButton(icon: Icons.settings),
                    if (mediaKitController.allowFullScreen)
                      _buildExpandButton(),
                  ],
                ),
              ),
              if (!mediaKitController.isLive)
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(
                      right: 20,
                      left: 20,
                      bottom: mediaKitController.isFullScreen ? 5.0 : 0,
                    ),
                    child: Row(
                      children: [
                        _buildProgressBar(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return TextButton(
      onPressed: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight + (mediaKitController.isFullScreen ? 15.0 : 0),
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              mediaKitController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton =
        widget.showPlayButton && !_dragging && !notifier.hideStuff;

    return GestureDetector(
      onTap: () {
        if (_latestValue.playing) {
          if (_displayTapped) {
            setState(() {
              notifier.hideStuff = true;
            });
          } else {
            _cancelAndRestartTimer();
          }
        } else {
          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
        }
      },
      child: CenterPlayButton(
        backgroundColor: Colors.black54,
        iconColor: Colors.white,
        isFinished: isFinished,
        isPlaying: controller.state.playing,
        show: showPlayButton,
        onPressed: _playPause,
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: mediaKitController.useRootNavigator,
      builder: (context) => PlaybackSpeedDialog(
        speeds: mediaKitController.playbackSpeeds,
        selected: _latestValue.rate,
      ),
    );

    if (chosenSpeed != null) {
      controller.setRate(chosenSpeed);
    }

    if (_latestValue.playing) {
      _startHideTimer();
    }
  }

  double? getLatestVolume(Player controller) {
    if (_latestVolume == null || _latestVolume == 0) {
      return 0.5;
    }

    return _latestVolume;
  }

  Widget _buildMuteButton(
    Player controller,
  ) {
    return TextButton(
      onPressed: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(getLatestVolume(controller) ?? 0.5);
        } else {
          _latestVolume = controller.state.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              right: 15.0,
            ),
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPause(Player controller) {
    return TextButton(
      onPressed: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: AnimatedPlayPause(
          playing: controller.state.playing,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: const TextStyle(
        fontSize: 14.0,
        color: Colors.white,
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = mediaKitController.subtitle?.isNotEmpty ?? false;
    buffering = controller.streams.buffer.listen((event) {
      _updateState();
    });
    volume = controller.streams.volume.listen((event) {
      _updateState();
    });

    _updateState();

    if (controller.state.playing || mediaKitController.autoPlay) {
      _startHideTimer();
    }

    if (mediaKitController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      notifier.hideStuff = true;

      mediaKitController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.state.playing) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (controller.state.duration.inMicroseconds == 0) {
          controller.play();
        } else {
          if (isFinished) {
            controller.seek(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = mediaKitController.hideControlsTimer.isNegative
        ? MediaKitController.defaultHideControlsTimer
        : mediaKitController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (mediaKitController.progressIndicatorDelay != null) {
      if (controller.state.buffering) {
        _bufferingDisplayTimer ??= Timer(
          mediaKitController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.state.buffering;
    }

    setState(() {
      _latestValue = controller.state;
      _subtitlesPosition = controller.state.position;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: MaterialVideoProgressBar(
        controller,
        colors: mediaKitController.materialProgressColors ??
            MediaKitProgressColors(
              playedColor: Theme.of(context).colorScheme.secondary,
              handleColor: Theme.of(context).colorScheme.secondary,
              bufferedColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.5),
              backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
            ),
      ),
    );
  }
}
