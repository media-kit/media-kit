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
        configuration: configuration.value,
      );
      players.add(player);
      controllers.add(controller);
    }
    for (int i = 0; i < count; i++) {
      players[i].setAudioTrack(AudioTrack.no());
      players[i].setPlaylistMode(PlaylistMode.loop);
      players[i].open(Media(sources[i % sources.length]));
      players[i].stream.error.listen((error) => debugPrint(error));
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
    final children = controllers.map(
      (e) {
        final video = Video(controller: e);
        if (Theme.of(context).platform == TargetPlatform.android) {
          return video;
        }
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: video,
        );
      },
    ).toList();
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
