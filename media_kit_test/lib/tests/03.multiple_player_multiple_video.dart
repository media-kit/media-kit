import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_test/common/widgets.dart';

class MultiplePlayerMultipleVideoScreen extends StatefulWidget {
  const MultiplePlayerMultipleVideoScreen({Key? key}) : super(key: key);

  @override
  State<MultiplePlayerMultipleVideoScreen> createState() =>
      _MultiplePlayerMultipleVideoScreenState();
}

class _MultiplePlayerMultipleVideoScreenState
    extends State<MultiplePlayerMultipleVideoScreen> {
  final List<Player> players = [Player(), Player()];
  List<VideoController?> controllers = [null, null];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      for (int i = 0; i < players.length; i++) {
        controllers[i] = await VideoController.create(players[i].handle);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      debugPrint('Disposing [Player]s and [VideoController]s...');
      for (int i = 0; i < players.length; i++) {
        await controllers[i]?.dispose();
        await players[i].dispose();
      }
    });
    super.dispose();
  }

  List<Widget> getAssetsListForIndex(int i) => [
        const Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            top: 16.0,
            bottom: 16.0,
          ),
          child: Text('Asset Videos:'),
        ),
        const Divider(height: 1.0, thickness: 1.0),
        for (int j = 0; j < 5; j++)
          ListTile(
            title: Text(
              'video_$j.mp4',
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              players[i].open(Media('asset://assets/video_$j.mp4'));
            },
          ),
      ];

  Widget getVideoForIndex(int i) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Card(
              elevation: 8.0,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(32.0),
              child: Video(
                controller: controllers[i],
              ),
            ),
          ),
          SeekBar(player: players[i]),
          const SizedBox(height: 32.0),
        ],
      );

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
              children: [
                for (int i = 0; i < 2; i++)
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width / 2,
                          height: MediaQuery.of(context).size.width /
                              2 *
                              12.0 /
                              16.0,
                          child: getVideoForIndex(i),
                        ),
                        const Divider(height: 1.0, thickness: 1.0),
                        ...getAssetsListForIndex(i),
                      ],
                    ),
                  ),
              ],
            )
          : ListView(
              children: [
                for (int i = 0; i < 2; i++) ...[
                  Container(
                    alignment: Alignment.center,
                    width: (MediaQuery.of(context).size.width - 64.0),
                    height: (MediaQuery.of(context).size.width - 64.0),
                    child: getVideoForIndex(i),
                  ),
                  const Divider(height: 1.0, thickness: 1.0),
                  ...getAssetsListForIndex(i),
                ]
              ],
            ),
    );
  }
}
