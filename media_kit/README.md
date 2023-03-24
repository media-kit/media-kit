# [package:media_kit](https://github.com/alexmercerind/media_kit)

A complete video & audio library for Flutter & Dart.

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml)

<hr>

<strong>Sponsored with 💖 by</strong>
<br>
<a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
<img alt="Stream Chat" width="350" height="auto" src="https://user-images.githubusercontent.com/28951144/204903022-bbaa49ca-74c2-4a8f-a05d-af8314bfd2cc.svg">
</a>
<br>

<h6>
  Rapidly ship in-app messaging with Stream's highly reliable chat infrastructure & feature-rich SDKs, including Flutter!
</h6>

<strong>
  <a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  Try the Flutter Chat tutorial
  </a>
</strong>

<hr>

![](https://user-images.githubusercontent.com/28951144/221628306-e240b292-52be-478c-9661-fffe6c3b445a.jpg)


## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit: ^0.0.1
  # For video rendering.
  media_kit_video: ^0.0.1
  # For enabling support for more than 8 simultaneous players.
  media_kit_native_event_loop: ^1.0.0
  # Pick based on your requirements / platform:
  media_kit_libs_windows_video: ^1.0.0          # Windows package for video (& audio) native libraries.
  media_kit_libs_windows_audio: ^1.0.0          # Windows package for audio (only) native libraries.
  media_kit_libs_ios_video: ^1.0.0              # iOS package for video (& audio) native libraries.
  media_kit_libs_macos_video: ^1.0.0            # macOS package for video (& audio) native libraries.
  media_kit_libs_linux: ^1.0.0                  # Linux dependency package.
```

## Platforms

| Platform | Audio | Video |
| -------- | ----- | ----- |
| Windows  | Ready | Ready |
| Linux    | Ready | Ready |
| macOS    | Ready | Ready |
| iOS      | Ready | Ready |
| Android  | Soon  | Soon  |

## Docs

### Brief Start

```dart
import 'package:media_kit/media_kit.dart';

final player = Player();

...

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

...

await player.open(
  Playlist(
    [
      Media('file:///C:/Users/Hitesh/Music/Sample.mp3'),
      Media('file:///C:/Users/Hitesh/Video/Sample.mkv'),
      Media('https://www.example.com/sample.mp4'),
      Media('rtsp://www.example.com/live'),
    ],
  ),
);

...

await player.play();
await player.pause();
await player.playOrPause();
await player.seek(const Duration(seconds: 10));

...

await player.next();
await player.previous();
await player.jump(2);
await player.add(Media('https://www.example.com/sample.mp4'));
await player.move(0, 2);

...

await player.setRate(1.0);
await player.setPitch(1.2);
await player.setVolume(50.0);
await player.setShuffle(false);
await player.setPlaylistMode(PlaylistMode.loop);
await player.setAudioDevice(AudioDevice.auto());

...

await player.dispose();

```

### Rendering Video

Performant & H/W accelerated, automatically fallbacks to S/W rendering if system does not support it.

```dart
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  // Create a [Player] instance from `package:media_kit`.
  final Player player = Player();
  // Reference to the [VideoController] instance from `package:media_kit_video`.
  VideoController? controller;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Create a [VideoController] instance from `package:media_kit_video`.
      // Pass the [handle] of the [Player] from `package:media_kit` to the [VideoController] constructor.
      controller = await VideoController.create(player.handle);
      // Must be created before opening any media. Otherwise, a separate window will be created.
      setState(() {});
    });
  }

  @override
  void dispose() {
    Future.microtask(() async {
      // Release allocated resources back to the system.
      await controller?.dispose();
      await player.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      /// Pass the [controller] to display the video output.
      controller: controller,
    );
  }
}
```

### Performance

Although [package:media_kit](https://github.com/alexmercerind/media_kit) is already fairly performant, you can further optimize things as follows:

**Note**

- You can limit size of the video output by specifying `width` & `height`.
- By default, both `height` & `width` are `null` i.e. output is based on video's resolution.

```dart
final controller = await VideoController.create(
  player.handle,
  width: 640,                                   // default: null
  height: 360,                                  // default: null
);
```

**Note**

- You can switch between GPU & CPU rendering by specifying `enableHardwareAcceleration`.
- By default, `enableHardwareAcceleration` is `true` i.e. GPU (Direct3D/OpenGL/METAL) is utilized.

```dart
final controller = await VideoController.create(
  player.handle,
  enableHardwareAcceleration: false,            // default: true
);
```

**Note**

- You can disable event callbacks for a `Player` & save yourself few CPU cycles.
- By default, `events` is `true` i.e. event streams & states are updated.

```dart
final player = Player(
  configuration: PlayerConfiguration(
    events: false,                              // default: true
  ),
);
```

### Detailed Guide

_TODO: documentation_

Try out [the test application](https://github.com/harmonoid/media_kit/blob/master/media_kit_test/lib/main.dart) for now.

## Setup

### Windows

Everything ready. Just add one of the following packages to your `pubspec.yaml`.

```yaml
dependencies:
  ...
  media_kit_libs_windows_video: ^1.0.0       # Windows package for video (& audio) native libraries.
  media_kit_libs_windows_audio: ^1.0.0       # Windows package for audio (only) native libraries.
```

### Linux

System shared libraries from distribution specific user-installed packages are used by-default. You can install these as follows.

#### Ubuntu / Debian

```bash
sudo apt install libmpv-dev mpv
```

#### Packaging

There are other ways to bundle these within your app package e.g. within Snap or Flatpak. Few examples:

- [Celluloid](https://github.com/celluloid-player/celluloid/blob/master/flatpak/io.github.celluloid_player.Celluloid.json)
- [VidCutter](https://github.com/ozmartian/vidcutter/tree/master/_packaging)

## Goals

The primary goal of [package:media_kit](https://github.com/alexmercerind/media_kit) is to become a **strong, stable, feature-proof & modular** media playback library for Flutter. The idea is to support both **audio & video playback**.

[package:media_kit](https://github.com/alexmercerind/media_kit) makes rendering [**hardware accelerated video playback**](https://github.com/alexmercerind/dart_vlc/issues/345) possible in Flutter.

Since, targetting multiple features at once & bundling redundant native libraries can result in increased bundle size of the application, you can manually select the native libraries you want to bundle, depending upon your use-case. The code is architectured to support multiple platforms & features. Support for more platforms will be added in future.

## Fund Development

If you find [package:media_kit](https://github.com/alexmercerind/media_kit) package(s) useful, please consider sponsoring me.

Since this is first of a kind project, it takes a lot of time to experiment & develop. It's a very tedious process to write code, document, maintain & provide support for free. Your support can ensure the quality of the package your project depends upon. I will feel rewarded for my hard-work & research.

- **[GitHub Sponsors](https://github.com/sponsors/alexmercerind)**
- **[PayPal](https://paypal.me/alexmercerind)**

<a href='https://github.com/sponsors/alexmercerind'><img src='https://github.githubassets.com/images/modules/site/sponsors/sponsors-mona.svg' width='240'></a>

Thanks!

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
