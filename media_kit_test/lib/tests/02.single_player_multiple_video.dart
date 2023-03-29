import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:media_kit_test/common/widgets.dart';

class SinglePlayerMultipleVideoScreen extends StatefulWidget {
  const SinglePlayerMultipleVideoScreen({Key? key}) : super(key: key);

  @override
  State<SinglePlayerMultipleVideoScreen> createState() =>
      _SinglePlayerMultipleVideoScreenState();
}

class _SinglePlayerMultipleVideoScreenState
    extends State<SinglePlayerMultipleVideoScreen> {
  final Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(player.handle);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      debugPrint('Disposing [Player] and [VideoController]...');
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  List<Widget> get assets => [
        const Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            top: 16.0,
            bottom: 16.0,
          ),
          child: Text('Asset Videos:'),
        ),
        const Divider(height: 1.0, thickness: 1.0),
        for (int i = 0; i < 5; i++)
          ListTile(
            title: Text(
              'video_$i.mp4',
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              player.open(Media('asset://assets/video_$i.mp4'));
            },
          ),
      ];

  Widget get video => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Card(
                    elevation: 8.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.fromLTRB(32.0, 32.0, 16.0, 8.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Video(
                        controller: controller,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 8.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.fromLTRB(16.0, 32.0, 32.0, 8.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Video(
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Card(
                    elevation: 8.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.fromLTRB(32.0, 8.0, 16.0, 32.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Video(
                        controller: controller,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 8.0,
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.fromLTRB(16.0, 8.0, 32.0, 32.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Video(
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TracksSelector(player: player),
          SeekBar(player: player),
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
      body: SizedBox.expand(
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      alignment: Alignment.center,
                      child: video,
                    ),
                  ),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      children: [...assets],
                    ),
                  ),
                ],
              )
            : ListView(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 12.0 / 16.0,
                    child: video,
                  ),
                  const Divider(height: 1.0, thickness: 1.0),
                  ...assets,
                ],
              ),
      ),
    );
  }
}
