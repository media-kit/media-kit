import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

class VideoControllerSetSizeScreen extends StatefulWidget {
  const VideoControllerSetSizeScreen({Key? key}) : super(key: key);

  @override
  State<VideoControllerSetSizeScreen> createState() =>
      _VideoControllerSetSizeScreenState();
}

class _VideoControllerSetSizeScreenState
    extends State<VideoControllerSetSizeScreen> {
  final Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(
        player,
        enableHardwareAcceleration: enableHardwareAcceleration.value,
      );
      await player.open(Media(sources[0]));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Video(controller: controller),
          Card(
            elevation: 4.0,
            margin: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 120.0,
              height: 64.0 * 6,
              child: ListView(
                children: [
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 2160 ~/ 1,
                      height: 2160,
                    ),
                    title: const Text(
                      '2160p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 1440 ~/ 1,
                      height: 1440,
                    ),
                    title: const Text(
                      '1440p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 1080 ~/ 1,
                      height: 1080,
                    ),
                    title: const Text(
                      '1080p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 720 ~/ 1,
                      height: 720,
                    ),
                    title: const Text(
                      '720p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 480 ~/ 1,
                      height: 480,
                    ),
                    title: const Text(
                      '480p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 360 ~/ 1,
                      height: 360,
                    ),
                    title: const Text(
                      '360p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 240 ~/ 1,
                      height: 240,
                    ),
                    title: const Text(
                      '240p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () => controller?.setSize(
                      width: 16 / 9 * 144 ~/ 1,
                      height: 144,
                    ),
                    title: const Text(
                      '144p',
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
