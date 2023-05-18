import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

class StressTestScreen extends StatefulWidget {
  const StressTestScreen({Key? key}) : super(key: key);

  @override
  State<StressTestScreen> createState() => _StressTestScreenState();
}

class _StressTestScreenState extends State<StressTestScreen> {
  static const int count = 8;

  final List<Player> players = [];
  final List<VideoController> controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < count; i++) {
      final player = Player();
      final controller = VideoController(
        player,
        enableHardwareAcceleration: enableHardwareAcceleration.value,
      );
      players.add(player);
      controllers.add(controller);
    }
    for (int i = 0; i < count; i++) {
      players[i].setVolume(0.0);
      players[i].setPlaylistMode(PlaylistMode.loop);
      players[i].open(Media(sources[i % sources.length]));
    }
  }

  @override
  void dispose() {
    for (final player in players) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = controllers
        .map(
          (e) => Card(
            elevation: 4.0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Video(controller: e),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: GridView.extent(
        maxCrossAxisExtent: 480.0,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 16.0 / 9.0,
        children: children,
      ),
    );
  }
}
