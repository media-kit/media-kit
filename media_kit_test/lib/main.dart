import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: _fontFamily,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text(
              'Single [Player] with single [Video] • File & Asset',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SimpleScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Single [Player] with single [Video] • URI',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SimpleStream(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Single [Player] with multiple [Video]s',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const SinglePlayerMultipleVideosScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Multiple [Player]s with multiple [Video]s',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const MultiplePlayersMultipleVideosScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Multiple [Player]s with multiple [Video]s • Tabs',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const MultiplePlayersMultipleVideosTabsScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text(
              'Stress Test',
              style: TextStyle(fontSize: 14.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StressTestScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Single [Player] with single [Video] • File & Asset.

class SimpleScreen extends StatefulWidget {
  const SimpleScreen({Key? key}) : super(key: key);

  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.warn,
    ),
  );
  // Reference to the [VideoController] instance.
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    pipeLogsToConsole(player);
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
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
        floatingActionButton: FloatingActionButton(
          tooltip: 'Open [File]',
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

// Single [Player] with single [Video] • File & Asset.

class SimpleStream extends StatefulWidget {
  const SimpleStream({Key? key}) : super(key: key);

  @override
  State<SimpleStream> createState() => _SimpleStreamState();
}

class _SimpleStreamState extends State<SimpleStream> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.warn,
    ),
  );
  // Reference to the [VideoController] instance.
  VideoController? controller;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _video = TextEditingController();
  final TextEditingController _audio = TextEditingController();

  @override
  void initState() {
    super.initState();
    pipeLogsToConsole(player);
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
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
      // [TextEditingController].
      _video.dispose();
      _audio.dispose();
    });
    super.dispose();
  }

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
          TracksSelector(player: player),
          SeekBar(player: player),
          const SizedBox(height: 32.0),
        ],
      );

  Widget get form => Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _video,
                style: const TextStyle(fontSize: 14.0),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Video URI',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URI';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _audio,
                style: const TextStyle(fontSize: 14.0),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Audio URI (Optional)',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Set libmpv options directly.
                      if (player.platform is libmpvPlayer) {
                        (player.platform as libmpvPlayer)
                            .setProperty("audio-files", _audio.text);
                      }
                      player.open(
                        Playlist(
                          [
                            Media(_video.text),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: SizedBox.expand(
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      child: video,
                    ),
                  ),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  Expanded(
                    flex: 1,
                    child: form,
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
                  form,
                ],
              ),
      ),
    );
  }
}

// Single [Player] with multiple [Video]s.

class SinglePlayerMultipleVideosScreen extends StatefulWidget {
  const SinglePlayerMultipleVideosScreen({Key? key}) : super(key: key);

  @override
  State<SinglePlayerMultipleVideosScreen> createState() =>
      _SinglePlayerMultipleVideosScreenState();
}

class _SinglePlayerMultipleVideosScreenState
    extends State<SinglePlayerMultipleVideosScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player();
  // Reference to the [VideoController] instance.
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Open [File]',
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
      ),
    );
  }
}

// Multiple [Player]s with multiple [Video]s

class MultiplePlayersMultipleVideosScreen extends StatefulWidget {
  const MultiplePlayersMultipleVideosScreen({Key? key}) : super(key: key);

  @override
  State<MultiplePlayersMultipleVideosScreen> createState() =>
      _MultiplePlayersMultipleVideosScreenState();
}

class _MultiplePlayersMultipleVideosScreenState
    extends State<MultiplePlayersMultipleVideosScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final List<Player> players = [Player(), Player()];
  // Reference to the [VideoController] instance.
  List<VideoController?> controllers = [null, null];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
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
              players[i].open(
                Playlist(
                  [
                    Media(
                      'asset://assets/video_$j.mp4',
                    ),
                  ],
                ),
              );
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

class TracksSelector extends StatefulWidget {
  final Player player;

  const TracksSelector({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  State<TracksSelector> createState() => _TracksSelectorState();
}

class _TracksSelectorState extends State<TracksSelector> {
  final List<StreamSubscription> _subscriptions = [];
  Track track = const Track();
  Tracks tracks = const Tracks();

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll(
      [
        widget.player.streams.track.listen((event) {
          setState(() {
            track = event;
          });
        }),
        widget.player.streams.tracks.listen((event) {
          setState(() {
            tracks = event;
          });
        }),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final s in _subscriptions) {
      s.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DropdownButton<VideoTrack>(
          icon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.videocam_outlined),
          ),
          value: track.video,
          items: tracks.video
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    '${e.id} • ${e.title} • ${e.language}',
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (track) {
            if (track != null) {
              widget.player.setVideoTrack(track);
            }
          },
        ),
        const SizedBox(width: 16.0),
        DropdownButton<AudioTrack>(
          icon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.audiotrack_outlined),
          ),
          value: track.audio,
          items: tracks.audio
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    '${e.id} • ${e.title} • ${e.language}',
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (track) {
            if (track != null) {
              widget.player.setAudioTrack(track);
            }
          },
        ),
        const SizedBox(width: 16.0),
        DropdownButton<SubtitleTrack>(
          icon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.subtitles_outlined),
          ),
          value: track.subtitle,
          items: tracks.subtitle
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    '${e.id} • ${e.title} • ${e.language}',
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (track) {
            if (track != null) {
              widget.player.setSubtitleTrack(track);
            }
          },
        ),
        const SizedBox(width: 48.0),
      ],
    );
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
  bool playing = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    playing = widget.player.state.playing;
    position = widget.player.state.position;
    duration = widget.player.state.duration;
    subscriptions.addAll(
      [
        widget.player.streams.playing.listen((event) {
          setState(() {
            playing = event;
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
            playing ? Icons.pause : Icons.play_arrow,
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

// Stress test.

class StressTestScreen extends StatefulWidget {
  const StressTestScreen({Key? key}) : super(key: key);

  @override
  State<StressTestScreen> createState() => _StressTestScreenState();
}

class _StressTestScreenState extends State<StressTestScreen> {
  static const int count = 20;
  List<Player> players = [];
  List<VideoController> controllers = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () async {
        for (int i = 0; i < count; i++) {
          final player = Player(
            configuration: const PlayerConfiguration(events: false),
          );
          final controller = await VideoController.create(player.handle);
          players.add(player);
          controllers.add(controller);
        }
        for (int i = 0; i < count; i++) {
          await players[i].open(
            Playlist([Media('asset://assets/video_${i % 5}.mp4')]),
            play: true,
          );
          await players[i].setPlaylistMode(PlaylistMode.loop);
          await players[i].setVolume(0.0);
        }
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    Future.microtask(() async {
      for (final e in controllers) {
        await e.dispose();
      }
      for (final e in players) {
        await e.dispose();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = controllers
        .map(
          (e) => Card(
            elevation: 4.0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Video(controller: e),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('package:media_kit'),
      ),
      body: MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height
          ? GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16.0),
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 16.0 / 9.0,
              children: children,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              children: children
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      width: MediaQuery.of(context).size.width - 32.0,
                      height:
                          9 / 16.0 * (MediaQuery.of(context).size.width - 32.0),
                      child: e,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class MultiplePlayersMultipleVideosTabsScreen extends StatelessWidget {
  const MultiplePlayersMultipleVideosTabsScreen({Key? key}) : super(key: key);

  static const int count = 5;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: count,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('package:media_kit'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelStyle: TextStyle(
                  fontSize: 14.0,
                  fontFamily: _fontFamily,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.0,
                  fontFamily: _fontFamily,
                ),
                tabs: [
                  for (int i = 0; i < count; i++)
                    Tab(
                      text: 'video_$i.mp4',
                    ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            for (int i = 0; i < count; i++) TabScreen(i),
          ],
        ),
      ),
    );
  }
}

class TabScreen extends StatefulWidget {
  final int i;
  const TabScreen(this.i, {Key? key}) : super(key: key);
  @override
  State<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  Player player = Player();
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      controller = await VideoController.create(
        player.handle,
      );
      await player.open(
        Playlist(
          [
            Media('asset://assets/video_${widget.i}.mp4'),
          ],
        ),
      );
      await player.setPlaylistMode(PlaylistMode.loop);
      await player.setVolume(0.0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(controller: controller);
  }
}

String? _fontFamily = {
  'windows': 'Segoe UI',
  'linux': 'Inter',
  'macOS': 'SF Pro Text',
  'android': 'Roboto',
  'ios': 'SF Pro Text',
}[Platform.operatingSystem];

void pipeLogsToConsole(Player player) {
  player.streams.log.listen((event) {
    if (kDebugMode) {
      print("mpv: ${event.prefix}: ${event.level}: ${event.text}");
    }
  });
}
