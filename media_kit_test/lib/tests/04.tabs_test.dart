import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_test/tests/09.seamless.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

class TabsTest extends StatelessWidget {
  const TabsTest({super.key});

  static const int count = 5;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: count,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('package:media_kit'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.8 * kToolbarHeight),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const Seamless(),
                      ),
                    );
                  },
                  child: Container(
                    height: 0.8 * kToolbarHeight,
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: RichText(
                      text: TextSpan(
                        children: const [
                          TextSpan(
                            text: 'seamless.dart',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: ' provides practical & efficient example.',
                          ),
                          TextSpan(
                            text: '\n',
                          ),
                          TextSpan(
                            text: 'This is only for testing race conditions.',
                          ),
                        ],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Align(
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
              ],
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
  const TabView(this.i, {super.key});
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
    player.setAudioTrack(AudioTrack.no());
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
