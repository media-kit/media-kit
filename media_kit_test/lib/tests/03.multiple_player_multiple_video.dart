import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

class MultiplePlayerMultipleVideoScreen extends StatefulWidget {
  const MultiplePlayerMultipleVideoScreen({super.key});

  @override
  State<MultiplePlayerMultipleVideoScreen> createState() =>
      _MultiplePlayerMultipleVideoScreenState();
}

class _MultiplePlayerMultipleVideoScreenState
    extends State<MultiplePlayerMultipleVideoScreen> {
  late final List<Player> players = [
    Player(),
    Player(),
  ];
  late final List<VideoController> controllers = [
    VideoController(
      players[0],
      configuration: configuration.value,
    ),
    VideoController(
      players[1],
      configuration: configuration.value,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final player in players) {
      player.open(Media(sources[0]));
      player.stream.error.listen((error) => debugPrint(error));
    }
  }

  @override
  void dispose() {
    for (final player in players) {
      player.dispose();
    }
    super.dispose();
  }

  List<Widget> getAssetsListForIndex(BuildContext context, int i) => [
        for (int j = 0; j < sources.length; j++)
          ListTile(
            title: Text(
              'Video $j',
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              players[i].open(Media(sources[j]));
            },
          ),
      ];

  Widget getVideoForIndex(BuildContext context, int i) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height
          ? Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(32.0),
              child: Video(controller: controllers[i]),
            )
          : Video(
              controller: controllers[i],
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body:
          MediaQuery.of(context).size.width > MediaQuery.of(context).size.height
              ? Row(
                  children: [
                    for (int i = 0; i < 2; i++)
                      Expanded(
                        child: ListView(
                          children: [
                            AspectRatio(
                              aspectRatio: 16.0 / 12.0,
                              child: getVideoForIndex(context, i),
                            ),
                            ...getAssetsListForIndex(context, i),
                          ],
                        ),
                      ),
                  ],
                )
              : ListView(
                  children: [
                    for (int i = 0; i < 2; i++) ...[
                      getVideoForIndex(context, i),
                      ...getAssetsListForIndex(context, i),
                    ]
                  ],
                ),
    );
  }
}
