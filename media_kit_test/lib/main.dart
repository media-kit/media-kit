import 'dart:async';

import 'package:file_picker/file_picker.dart';
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

  Widget get video => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Card(
              elevation: 8.0,
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(32.0),
              child: Video(
                controller: controller,
              ),
            ),
          ),
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
        floatingActionButton: FloatingActionButton(
          tooltip: 'Open File',
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
            );
            if (result?.files.isNotEmpty ?? false) {
              player.open(
                Playlist(
                  [
                    Media(result!.files.first.path!),
                  ],
                ),
              );
            }
          },
          child: const Icon(Icons.file_open),
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
        ));
  }
}

class SeekBar extends StatefulWidget {
  final Player player;
  const SeekBar({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    isPlaying = widget.player.state.isPlaying;
    position = widget.player.state.position;
    duration = widget.player.state.duration;
    subscriptions.addAll(
      [
        widget.player.streams.isPlaying.listen((event) {
          setState(() {
            isPlaying = event;
          });
        }),
        widget.player.streams.position.listen((event) {
          setState(() {
            position = event;
          });
        }),
        widget.player.streams.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final s in subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 48.0),
        IconButton(
          onPressed: widget.player.playOrPause,
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          color: Theme.of(context).primaryColor,
          iconSize: 36.0,
        ),
        const SizedBox(width: 24.0),
        Text(position.toString().substring(2, 7)),
        Expanded(
          child: Slider(
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            value: position.inMilliseconds.toDouble().clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
            onChanged: (e) {
              setState(() {
                position = Duration(milliseconds: e ~/ 1);
              });
            },
            onChangeEnd: (e) {
              widget.player.seek(Duration(milliseconds: e ~/ 1));
            },
          ),
        ),
        Text(duration.toString().substring(2, 7)),
        const SizedBox(width: 48.0),
      ],
    );
  }
}
