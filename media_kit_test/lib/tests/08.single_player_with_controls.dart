import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video_controls/widgets/widgets.dart';

import '../common/sources.dart';
import '../common/widgets.dart';

class SinglePlayerWithControls extends StatefulWidget {
  const SinglePlayerWithControls({Key? key}) : super(key: key);

  @override
  State<SinglePlayerWithControls> createState() =>
      _SinglePlayerWithControlsState();
}

class _SinglePlayerWithControlsState extends State<SinglePlayerWithControls> {
  final Player player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.warn,
    ),
  );
  MediaKitController? mediaKitController;
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      mediaKitController = MediaKitController(
        player: player,
        videoController: await VideoController.create(player),
        autoPlay: true,
        looping: true,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      debugPrint('Disposing [Player] and [VideoController]...');
      await player.dispose();
      mediaKitController?.dispose();
    });
    super.dispose();
  }

  List<Widget> get items => [
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
            heroTag: 'file',
            tooltip: 'Open [File]',
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.any,
              );
              if (result?.files.isNotEmpty ?? false) {
                await player.open(Media(result!.files.first.path!));
              }
            },
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
      body: Center(
        child: mediaKitController != null
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
                                elevation: 8.0,
                                clipBehavior: Clip.antiAlias,
                                margin: const EdgeInsets.all(32.0),
                                child: MediaKitVideo(
                                  controller: mediaKitController!,
                                )),
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Pick a video'),
                ],
              ),
      ),
    );
  }
}
