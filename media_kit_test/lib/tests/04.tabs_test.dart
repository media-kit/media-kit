import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

class TabsTest extends StatelessWidget {
  const TabsTest({Key? key}) : super(key: key);

  static const int count = 5;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: count,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('package:media_kit'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelStyle: const TextStyle(fontSize: 14.0),
                unselectedLabelStyle: const TextStyle(fontSize: 14.0),
                tabs: [
                  for (int i = 0; i < count; i++)
                    Tab(
                      text: 'Video $i',
                    ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            for (int i = 0; i < count; i++) TabView(i),
          ],
        ),
      ),
    );
  }
}

class TabView extends StatefulWidget {
  final int i;
  const TabView(this.i, {Key? key}) : super(key: key);
  @override
  State<TabView> createState() => TabViewState();
}

class TabViewState extends State<TabView> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
    player.setVolume(0.0);
    player.setPlaylistMode(PlaylistMode.loop);
    player.open(Media(sources[widget.i % sources.length]));
    player.stream.error.listen((error) => debugPrint(error));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: NoVideoControls,
    );
  }
}
