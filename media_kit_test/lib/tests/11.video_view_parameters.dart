import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';
import '../common/widgets.dart';

class VideoViewParametersScreen extends StatefulWidget {
  const VideoViewParametersScreen({super.key});

  @override
  State<VideoViewParametersScreen> createState() =>
      _VideoViewParametersScreenState();
}

class _VideoViewParametersScreenState extends State<VideoViewParametersScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  // A [GlobalKey<VideoState>] is required to access the programmatic video view parameters interface.
  late final GlobalKey<VideoState> key = GlobalKey<VideoState>();

  BoxFit fit = BoxFit.contain;

  int fitTick = 0;
  int fontSizeTick = 0;
  Timer? fitTimer;
  Timer? fontSizeTimer;
  @override
  void initState() {
    super.initState();
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint(error));
  }

  @override
  void dispose() {
    player.dispose();

    fitTimer?.cancel();
    fontSizeTimer?.cancel();
    super.dispose();
  }

  List<Widget> get items => [
        const SizedBox(height: 16.0),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (fitTimer == null) {
                fitTimer = Timer.periodic(
                  const Duration(seconds: 1),
                  (timer) {
                    if (timer.tick % 3 == 0 /* Every 3 seconds. */) {
                      fit =
                          fit == BoxFit.contain ? BoxFit.none : BoxFit.contain;
                      setState(() {});
                    }
                    if (mounted) {
                      setState(() {
                        fitTick = timer.tick;
                      });
                    }
                  },
                );
              } else {
                fitTimer?.cancel();
                fitTimer = null;
              }
              setState(() {});
            },
            child: Text(
              fitTimer == null
                  ? 'Cycle BoxFit'
                  : 'BoxFit: $fit (${3 - fitTick % 3})',
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (fontSizeTimer == null) {
                fontSizeTimer = Timer.periodic(
                  const Duration(seconds: 1),
                  (timer) {
                    if (timer.tick % 3 == 0 /* Every 3 seconds. */) {
                      key.currentState?.update(
                        subtitleViewConfiguration: SubtitleViewConfiguration(
                            style: TextStyle(
                          // font size increases every 3 seconds
                          fontSize: fontSizeFromTick(timer.tick),
                        )),
                      );
                    }
                    if (mounted) {
                      setState(() {
                        fontSizeTick = timer.tick;
                      });
                    }
                  },
                );
              } else {
                fontSizeTimer?.cancel();
                fontSizeTimer = null;
              }
              setState(() {});
            },
            child: Text(
              fontSizeTimer == null
                  ? 'Cycle Font'
                  : 'Font: ${fontSizeFromTick(fontSizeTick)}',
            ),
          ),
        ),
      ];

  double fontSizeFromTick(int tick) =>
      20.0 + (tick % 6 < 3 ? tick % 6 : 6 - tick % 6) * 10.0;

  @override
  Widget build(BuildContext context) {
    final horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'file',
            tooltip: 'Open [File]',
            onPressed: () => showFilePicker(context, player),
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            heroTag: 'uri',
            tooltip: 'Open [Uri]',
            onPressed: () => showURIPicker(context, player),
            child: const Icon(Icons.link),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              margin: const EdgeInsets.all(32.0),
                              child: Video(
                                key: key,
                                fit: fit,
                                controller: controller,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: items,
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  Video(
                    key: key,
                    fit: fit,
                    controller: controller,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                  ),
                  ...items,
                ],
              ),
      ),
    );
  }
}
