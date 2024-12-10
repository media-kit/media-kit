import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_platform/universal_platform.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';

// A simple example to show how buffering & initial black screen can be avoided by writing code effectively.

class Seamless extends StatefulWidget {
  const Seamless({Key? key}) : super(key: key);

  @override
  State<Seamless> createState() => _SeamlessState();
}

class _SeamlessState extends State<Seamless> {
  final pageController = PageController(initialPage: 0);

  // To efficiently call [setState] if required for re-build.
  final early = HashSet<int>();

  late final players = HashMap<int, Player>();
  late final controllers = HashMap<int, VideoController>();

  @override
  void initState() {
    // First two pages are loaded initially.
    Future.wait([
      createPlayer(0),
      createPlayer(1),
    ]).then((_) {
      // First video must be played initially.
      players[0]?.play();
    });

    super.initState();
  }

  @override
  void dispose() {
    for (final player in players.values) {
      player.dispose();
    }
    super.dispose();
  }

  // Just create a new [Player] & [VideoController], load the video & save it.
  Future<void> createPlayer(int page) async {
    final player = Player();
    final controller = VideoController(
      player,
      configuration: configuration.value,
    );
    if (!UniversalPlatform.isWeb) {
      await player.setAudioTrack(AudioTrack.no());
    }
    await player.setPlaylistMode(PlaylistMode.loop);
    await player.open(
      // Load a random video from the list of sources.
      Media(sources[Random().nextInt(sources.length)]),
      play: false,
    );
    players[page] = player;
    controllers[page] = controller;

    if (early.contains(page)) {
      early.remove(page);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            onPageChanged: (i) {
              // Play the current page's video.
              players[i]?.play();

              // Dispose the [Player]s & [VideoController]s of the pages that are not visible & not adjacent to the current page.
              players.removeWhere(
                (page, player) {
                  final remove = ![i, i - 1, i + 1].contains(page);
                  if (remove) {
                    player.dispose();
                  }
                  return remove;
                },
              );
              controllers.removeWhere(
                (page, controller) {
                  final remove = ![i, i - 1, i + 1].contains(page);
                  return remove;
                },
              );

              // Pause other pages' videos.
              for (final e in players.entries) {
                if (e.key != i) {
                  e.value.pause();
                  e.value.seek(Duration.zero);
                }
              }

              // Create the [Player]s & [VideoController]s for the next & previous page.
              // It is obvious that current page's [Player] & [VideoController] will already exist, still checking it redundantly
              if (!players.containsKey(i)) {
                createPlayer(i);
              }
              if (!players.containsKey(i + 1)) {
                createPlayer(i + 1);
              }
              if (!players.containsKey(i - 1)) {
                createPlayer(i - 1);
              }

              debugPrint('players: ${players.keys}');
              debugPrint('controllers: ${controllers.keys}');
            },
            itemBuilder: (context, i) {
              final controller = controllers[i];
              if (controller == null) {
                early.add(i);
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xffffffff),
                  ),
                );
              }

              return Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              );
            },
            controller: pageController,
            scrollDirection: Axis.vertical,
          ),
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.black38,
                    child: InkWell(
                      onTap: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.expand_less,
                          size: 28.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 8),
                Expanded(
                  child: Material(
                    color: Colors.black38,
                    child: InkWell(
                      onTap: () {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.expand_more,
                          size: 28.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
