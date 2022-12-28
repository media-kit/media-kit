import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_core_video/media_kit_core_video.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyScreen(),
    );
  }
}

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player();
  // Reference to the [VideoController] instance.
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Create a [VideoController] instance from `package:media_kit_core_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
      controller = await VideoController.create(player.handle);
      setState(() {});
    });
  }

  List<Widget> get assets => [
        for (int i = 0; i < 5; i++)
          ListTile(
            title: Text('video_$i.mp4'),
            onTap: () {
              player.open(
                Playlist(
                  [
                    Media(
                      'asset://assets/video_$i.mp4',
                    ),
                  ],
                ),
              );
            },
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 8.0,
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.all(32.0),
                      child: Video(
                        controller: controller,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1.0, thickness: 1.0),
                Expanded(
                  flex: 1,
                  child: ListView(
                    children: assets,
                  ),
                ),
              ],
            )
          : ListView(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                  child: Card(
                    elevation: 8.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.all(32.0),
                    child: Video(
                      controller: controller,
                    ),
                  ),
                ),
                const Divider(height: 1.0, thickness: 1.0),
                ...assets,
              ],
            ),
    );
  }
}
