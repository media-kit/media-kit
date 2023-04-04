import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// ignore_for_file: use_build_context_synchronously

Future<void> paintFirstFrame(BuildContext context) async {
  // Create [Player] and [VideoController] instances.
  List<Player> players = [
    Player(),
    Player(),
    Player(),
    Player(),
    Player(),
  ];
  List<VideoController> controllers = [
    await VideoController.create(players[0].handle),
    await VideoController.create(players[1].handle),
    await VideoController.create(players[2].handle),
    await VideoController.create(players[3].handle),
    await VideoController.create(players[4].handle),
  ];
  // Open some [Playable]s.
  // Do not start playback i.e. play: false.
  for (int i = 0; i < 5; i++) {
    await players[i].open(
      Media('asset://assets/video_${i % 5}.mp4'),
      play: false,
    );
  }

  // Some voluntary delay.
  await Future.delayed(const Duration(seconds: 1));

  // The first frame should be painted!
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PaintFirstFrameScreen(
        players: players,
        controllers: controllers,
      ),
    ),
  );
  for (final e in controllers) {
    await e.dispose();
  }
  for (final e in players) {
    await e.dispose();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          for (final player in players) {
            player.playOrPause();
          }
        },
        child: const Icon(Icons.play_arrow),
      ),
      body: ListView.separated(
        itemCount: 5,
        itemBuilder: (context, i) => Video(
          controller: controllers[i],
          width: MediaQuery.of(context).size.width.clamp(0, 480.0),
          height:
              MediaQuery.of(context).size.width.clamp(0, 480.0) * 9.0 / 16.0,
          fill: Colors.transparent,
        ),
        separatorBuilder: (context, i) => const SizedBox(height: 16.0),
        padding: const EdgeInsets.all(16.0),
      ),
    );
  }
}
