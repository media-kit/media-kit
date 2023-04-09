#### Control audio or video playback

```dart
import 'package:media_kit/media_kit.dart';

/// Create a [Player] instance for audio or video playback.

final player = Player();

/// Subscribe to event streams & listen to updates.

player.streams.playlist.listen((e) => print(e));
player.streams.playing.listen((e) => print(e));
player.streams.completed.listen((e) => print(e));
player.streams.position.listen((e) => print(e));
player.streams.duration.listen((e) => print(e));
player.streams.volume.listen((e) => print(e));
player.streams.rate.listen((e) => print(e));
player.streams.pitch.listen((e) => print(e));
player.streams.buffering.listen((e) => print(e));
player.streams.audioParams.listen((e) => print(e));
player.streams.audioBitrate.listen((e) => print(e));
player.streams.audioDevice.listen((e) => print(e));
player.streams.audioDevices.listen((e) => print(e));


/// Open a playable [Media] or [Playlist].

await player.open(Media('file:///C:/Users/Hitesh/Music/Sample.mp3'));
await player.open(Media('file:///C:/Users/Hitesh/Video/Sample.mkv'));
await player.open(Media('asset:///videos/bee.mp4'));
await player.open(
  Playlist(
    [
      Media('https://www.example.com/sample.mp4'),
      Media('rtsp://www.example.com/live'),
    ],
    /// Select the starting index.
    index: 1,
  ),
  /// Select whether playback should start or not.
  play: false,
);

/// Control playback state.

await player.play();
await player.pause();
await player.playOrPause();
await player.seek(const Duration(seconds: 10));

/// Use or modify the queue.

await player.next();
await player.previous();
await player.jump(2);
await player.add(Media('https://www.example.com/sample.mp4'));
await player.move(0, 2);

/// Customize speed, pitch, volume, shuffle, playlist mode, audio device.

await player.setRate(1.0);
await player.setPitch(1.2);
await player.setVolume(50.0);
await player.setShuffle(false);
await player.setPlaylistMode(PlaylistMode.loop);
await player.setAudioDevice(AudioDevice.auto());

/// Release allocated resources back to the system.

await player.dispose();
```

#### Display video output

Performant & H/W accelerated, automatically fallbacks to S/W rendering if system does not support it.

```dart
import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart';                        /// Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';            /// Provides [VideoController] & [Video] etc.

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  /// Create a [Player].
  final Player player = Player();
  /// Store reference to the [VideoController].
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      /// Create a [VideoController] to show video output of the [Player].
      controller = await VideoController.create(player);
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      /// Release allocated resources back to the system.
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Use [Video] widget to display the output.
    return Video(
      /// Pass the [controller].
      controller: controller,
    );
  }
}
```
