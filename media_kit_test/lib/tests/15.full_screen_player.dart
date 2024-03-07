import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_platform/universal_platform.dart';

import '../common/globals.dart';
import '../common/widgets.dart';
import '../common/sources/sources.dart';

class FullScreenPlayer extends StatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );
  // A [GlobalKey<VideoState>] is required to access the programmatic fullscreen interface.
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();

  @override
  void initState() {
    super.initState();
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint(error));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      key.currentState?.enterFullscreen();
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return // Wrap [Video] widget with [MaterialVideoControlsTheme].
        MaterialVideoControlsTheme(
            normal: MaterialVideoControlsThemeData(
              topButtonBar: topBar(context),
            ),
            fullscreen: MaterialVideoControlsThemeData(
              topButtonBar: topBar(context),
            ),
            child: // Wrap [Video] widget with [MaterialDesktopVideoControlsTheme].
                MaterialDesktopVideoControlsTheme(
                    normal: MaterialDesktopVideoControlsThemeData(
                      topButtonBar: topBar(context),
                    ),
                    fullscreen: MaterialDesktopVideoControlsThemeData(
                      topButtonBar: topBar(context),
                    ),
                    child: Video(
                      key: key,
                      controller: controller,
                      onEnterFullscreen: () async {
                        await defaultEnterNativeFullscreen();
                      },
                      onExitFullscreen: () async {
                        await defaultExitNativeFullscreen();
                        if (!UniversalPlatform.isDesktop) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                    )));
  }

  List<Widget> topBar(BuildContext context) {
    return [
      MaterialDesktopCustomButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (key.currentState?.isFullscreen() ?? false) {
            key.currentState?.exitFullscreen();
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      const Spacer(),
    ];
  }
}
