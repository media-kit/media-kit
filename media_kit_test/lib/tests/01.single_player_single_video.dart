import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../common/globals.dart';
import '../common/sources/sources.dart';
import '../common/widgets.dart';

class SinglePlayerSingleVideoScreen extends StatefulWidget {
  const SinglePlayerSingleVideoScreen({super.key});

  @override
  State<SinglePlayerSingleVideoScreen> createState() => _SinglePlayerSingleVideoScreenState();
}

class _SinglePlayerSingleVideoScreenState extends State<SinglePlayerSingleVideoScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  bool subtitlesEnabled = false;

  // Test video with subtitles (Sintel trailer)
  static const String videoWithSubtitles =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4';

  // Inline VTT subtitle data to avoid CORS issues on web
  static const String subtitleData = '''WEBVTT

00:00:00.000 --> 00:00:03.000
This is a test subtitle line 1

00:00:03.000 --> 00:00:06.000
This is a test subtitle line 2

00:00:06.000 --> 00:00:09.000
Subtitles are working correctly!

00:00:09.000 --> 00:00:12.000
Red text with black background

00:00:12.000 --> 00:00:15.000
Toggle subtitles with the button

00:00:15.000 --> 00:00:20.000
Enjoy watching the video!
''';

  @override
  void initState() {
    super.initState();
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint('Error: $error'));
    player.stream.subtitle.listen((subtitle) {
      debugPrint('Subtitle stream: $subtitle');
    });
    player.stream.track.listen((track) {
      debugPrint('Track changed: subtitle=${track.subtitle.id}');
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _toggleSubtitles() {
    if (subtitlesEnabled) {
      player.setSubtitleTrack(SubtitleTrack.no());
      setState(() {
        subtitlesEnabled = false;
      });
    } else {
      player.setSubtitleTrack(
        SubtitleTrack.data(
          subtitleData,
          title: 'English',
          language: 'en',
        ),
      );
      setState(() {
        subtitlesEnabled = true;
      });
    }
  }

  void _openVideoWithSubtitles() {
    player.open(Media(videoWithSubtitles));
    player.setSubtitleTrack(
      SubtitleTrack.data(
        subtitleData,
        title: 'English',
        language: 'en',
      ),
    );
    setState(() {
      subtitlesEnabled = true;
    });
  }

  List<Widget> get items => [
        ListTile(
          title: const Text(
            'Video with Subtitles (Sintel)',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('External SRT subtitles'),
          onTap: _openVideoWithSubtitles,
        ),
        const Divider(),
        for (int i = 0; i < sources.length; i++)
          ListTile(
            title: Text(
              'Video $i',
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              player.open(Media(sources[i]));
            },
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'subtitles',
            tooltip: subtitlesEnabled ? 'Disable Subtitles' : 'Enable Subtitles',
            onPressed: _toggleSubtitles,
            backgroundColor: subtitlesEnabled ? Colors.green : null,
            child: Icon(
              subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
            ),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            heroTag: 'file',
            tooltip: 'Open [File]',
            onPressed: () => showFilePicker(context, player),
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(width: 16.0),
          FloatingActionButton(
            heroTag: 'uri',
            tooltip: 'Open [Uri]',
            onPressed: () => showURIPicker(context, player),
            child: const Icon(Icons.link),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              margin: const EdgeInsets.all(32.0),
                              child: Video(
                                controller: controller,
                                subtitleViewConfiguration: const SubtitleViewConfiguration(
                                  style: TextStyle(
                                    height: 1.4,
                                    fontSize: 32.0,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Color(0xaa000000),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: items,
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  Video(
                    controller: controller,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                    subtitleViewConfiguration: const SubtitleViewConfiguration(
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 32.0,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...items,
                ],
              ),
      ),
    );
  }
}
