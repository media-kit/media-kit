import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_test/common/globals.dart';
import 'package:media_kit_test/common/sources/sources.dart';
import 'package:media_kit_test/common/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

class SinglePlayerMultipleVideoScreen extends StatefulWidget {
  const SinglePlayerMultipleVideoScreen({super.key});

  @override
  State<SinglePlayerMultipleVideoScreen> createState() =>
      _SinglePlayerMultipleVideoScreenState();
}

class _SinglePlayerMultipleVideoScreenState
    extends State<SinglePlayerMultipleVideoScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
    player.open(Media(sources[0]));
    player.stream.error.listen((error) => debugPrint(error));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  List<Widget> get items => [
        for (int i = 0; i < sources.length; i++)
          ListTile(
            title: Text(
              'Video $i',
              style: const TextStyle(fontSize: 14),
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
    final bool horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text('package:media_kit')),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'file',
            tooltip: 'Open [File]',
            onPressed: () async {
              final List<PlatformFile> result = await FilePicker.pickFiles();
              if (result.isNotEmpty) {
                await player.open(Media(result.first.path!));
              }
            },
            child: const Icon(Icons.file_open),
          ),
          const SizedBox(width: 16),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.black,
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Video(controller: controller),
                                      ),
                                      Expanded(
                                        child: Video(controller: controller),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Video(controller: controller),
                                      ),
                                      Expanded(
                                        child: Video(controller: controller),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: ListView(children: items)),
                ],
              )
            : ListView(
                children: [
                  Container(
                    color: Colors.black,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 9.0 / 16.0,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Video(
                                  controller: controller,
                                  controls: NoVideoControls,
                                ),
                              ),
                              Expanded(
                                child: Video(
                                  controller: controller,
                                  controls: NoVideoControls,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Video(
                                  controller: controller,
                                  controls: NoVideoControls,
                                ),
                              ),
                              Expanded(
                                child: Video(
                                  controller: controller,
                                  controls: NoVideoControls,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...items,
                ],
              ),
      ),
    );
  }
}
