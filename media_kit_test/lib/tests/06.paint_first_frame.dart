import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

Future<void> paintFirstFrame(BuildContext context) async {
  // Create [Player] and [VideoController] instances.
  final players = [
    Player(),
    Player(),
    Player(),
    Player(),
    Player(),
  ];
  final controllers = [
    VideoController(
      players[0],
      configuration: configuration.value,
    ),
    VideoController(
      players[1],
      configuration: configuration.value,
    ),
    VideoController(
      players[2],
      configuration: configuration.value,
    ),
    VideoController(
      players[3],
      configuration: configuration.value,
    ),
    VideoController(
      players[4],
      configuration: configuration.value,
    ),
  ];

  for (final controller in controllers) {
    controller.rect.addListener(
      () => debugPrint(controller.rect.value.toString()),
    );
  }

  // Open some [Playable]s. Do not start playback i.e. play: false.
  for (int i = 0; i < 5; i++) {
    await players[i].open(
      Playlist(
        sources.map((e) => Media(e)).toList(),
        index: i,
      ),
      play: false,
    );
  }

  await Future.wait(controllers.map((e) => e.waitUntilFirstFrameRendered));

  // The first frame should be drawn.
  if (context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaintFirstFrameScreen(
          players: players,
          controllers: controllers,
        ),
      ),
    );
  }

  for (final player in players) {
    await player.dispose();
  }
}

class PaintFirstFrameScreen extends StatelessWidget {
  final List<Player> players;
  final List<VideoController> controllers;
  const PaintFirstFrameScreen({
    Key? key,
    required this.players,
    required this.controllers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: ListView.separated(
        itemCount: controllers.length,
        itemBuilder: (context, i) {
          final video = SizedBox(
            height: 256.0,
            child: AspectRatio(
              aspectRatio: 16.0 / 9.0,
              child: Video(controller: controllers[i]),
            ),
          );
          if (Theme.of(context).platform == TargetPlatform.android) {
            return video;
          }
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: video,
          );
        },
        separatorBuilder: (context, i) => const SizedBox(height: 16.0),
        padding: const EdgeInsets.all(16.0),
      ),
    );
  }
}
