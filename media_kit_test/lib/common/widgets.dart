import 'dart:async';
import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';

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
        const SizedBox(width: 52.0),
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
  bool seeking = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration buffer = Duration.zero;

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
        widget.player.streams.playing.listen((event) {
          setState(() {
            playing = event;
          });
        }),
        widget.player.streams.completed.listen((event) {
          setState(() {
            position = Duration.zero;
          });
        }),
        widget.player.streams.position.listen((event) {
          setState(() {
            if (!seeking) position = event;
          });
        }),
        widget.player.streams.duration.listen((event) {
          setState(() {
            duration = event;
          });
        }),
        widget.player.streams.buffer.listen((event) {
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
    final horizontal =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Column(
      children: [
        const SizedBox(height: 16.0),
        if (!horizontal)
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: widget.player.playOrPause,
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                ),
                color: Theme.of(context).primaryColor,
                iconSize: 36.0,
              ),
              const Spacer(),
            ],
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 48.0),
            if (horizontal) ...[
              IconButton(
                onPressed: widget.player.playOrPause,
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                ),
                color: Theme.of(context).primaryColor,
                iconSize: 36.0,
              ),
              const SizedBox(width: 24.0),
            ],
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

Future<void> showURIPicker(BuildContext context, Player player) async {
  final key = GlobalKey<FormState>();
  final video = TextEditingController();
  final audio = TextEditingController();
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
                controller: video,
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
                controller: audio,
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
                    if (key.currentState!.validate()) {
                      if (player.platform is libmpvPlayer) {
                        (player.platform as libmpvPlayer).setProperty(
                          "audio-files",
                          audio.text,
                        );
                      }
                      player.open(Media(video.text));
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
