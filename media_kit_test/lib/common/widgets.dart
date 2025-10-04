import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'package:media_kit/media_kit.dart';

import '../common/sources/sources.dart';

class TracksSelector extends StatefulWidget {
  final Player player;

  const TracksSelector({
    super.key,
    required this.player,
  });

  @override
  State<TracksSelector> createState() => _TracksSelectorState();
}

class _TracksSelectorState extends State<TracksSelector> {
  late Track track = widget.player.state.track;
  late Tracks tracks = widget.player.state.tracks;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    track = widget.player.state.track;
    tracks = widget.player.state.tracks;
    subscriptions.addAll(
      [
        widget.player.stream.track.listen((track) {
          setState(() {
            this.track = track;
          });
        }),
        widget.player.stream.tracks.listen((tracks) {
          setState(() {
            this.tracks = tracks;
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
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DropdownButton<VideoTrack>(
            isExpanded: true,
            itemHeight: null,
            value: track.video,
            items: tracks.video
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${e.id} • ${e.title} • ${e.language}',
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (track) async {
              if (track != null) {
                await widget.player.setVideoTrack(track);
                setState(() {});
              }
            },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: DropdownButton<AudioTrack>(
            isExpanded: true,
            itemHeight: null,
            value: track.audio,
            items: tracks.audio
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${e.id} • ${e.title} • ${e.language}',
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (track) async {
              if (track != null) {
                await widget.player.setAudioTrack(track);
                setState(() {});
              }
            },
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: DropdownButton<SubtitleTrack>(
            isExpanded: true,
            itemHeight: null,
            value: track.subtitle,
            items: tracks.subtitle
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${e.id} • ${e.title} • ${e.language}',
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (track) async {
              if (track != null) {
                await widget.player.setSubtitleTrack(track);
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }
}

class SeekBar extends StatefulWidget {
  final Player player;
  const SeekBar({
    super.key,
    required this.player,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  late bool playing = widget.player.state.playing;
  late Duration position = widget.player.state.position;
  late Duration duration = widget.player.state.duration;
  late Duration buffer = widget.player.state.buffer;

  bool seeking = false;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    playing = widget.player.state.playing;
    position = widget.player.state.position;
    duration = widget.player.state.duration;
    buffer = widget.player.state.buffer;
    subscriptions.addAll(
      [
        widget.player.stream.playing.listen((event) {
          setState(() {
            playing = event;
          });
        }),
        widget.player.stream.completed.listen((event) {
          setState(() {
            position = Duration.zero;
          });
        }),
        widget.player.stream.position.listen((event) {
          setState(() {
            if (!seeking) position = event;
          });
        }),
        widget.player.stream.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
        widget.player.stream.buffer.listen((event) {
          setState(() {
            buffer = event;
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
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
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
                      0.0,
                      duration.inMilliseconds.toDouble(),
                    ),
                secondaryTrackValue: buffer.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble(),
                    ),
                onChangeStart: (e) {
                  seeking = true;
                },
                onChanged: position.inMilliseconds > 0
                    ? (e) {
                        setState(() {
                          position = Duration(milliseconds: e ~/ 1);
                        });
                      }
                    : null,
                onChangeEnd: (e) {
                  seeking = false;
                  widget.player.seek(Duration(milliseconds: e ~/ 1));
                },
              ),
            ),
            Text(duration.toString().substring(2, 7)),
            const SizedBox(width: 48.0),
          ],
        )
      ],
    );
  }
}

Future<void> showFilePicker(BuildContext context, Player player) async {
  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  if (result?.files.isNotEmpty ?? false) {
    final file = result!.files.first;
    if (kIsWeb) {
      await player.open(Media(convertBytesToURL(file.bytes!)));
    } else {
      await player.open(Media(file.path!));
    }
  }
}

Future<void> showURIPicker(BuildContext context, Player player) async {
  final key = GlobalKey<FormState>();
  final src = TextEditingController();
  await showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      alignment: Alignment.center,
      child: Form(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: src,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (key.currentState!.validate()) {
                      player.open(Media(src.text));
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
