import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources.dart';

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
            for (int i = 0; i < count; i++) _Viewport(i),
          ],
        ),
      ),
    );
  }
}

class _Viewport extends StatefulWidget {
  final int i;
  const _Viewport(this.i, {Key? key}) : super(key: key);
  @override
  State<_Viewport> createState() => __ViewportState();
}

class __ViewportState extends State<_Viewport> {
  Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(
        player,
        enableHardwareAcceleration: enableHardwareAcceleration.value,
      );
      await player.open(Media(sources[widget.i]));
      await player.setPlaylistMode(PlaylistMode.loop);
      await player.setVolume(0.0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(controller: controller);
  }
}
