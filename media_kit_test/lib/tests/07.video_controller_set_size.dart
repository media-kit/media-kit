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
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
    player.setAudioTrack(AudioTrack.no());
    player.setPlaylistMode(PlaylistMode.loop);
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint(error));
  }

  @override
  void dispose() {
    player.dispose();
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
          Video(
            controller: controller,
            controls: NoVideoControls,
          ),
          Card(
            margin: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 120.0,
              height: 64.0 * 6,
              child: ListView(
                children: [
                  ListTile(
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
                    onTap: () => controller.setSize(
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
