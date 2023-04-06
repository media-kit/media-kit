# [package:media_kit](https://github.com/alexmercerind/media_kit)

A complete video & audio playback library for Flutter & Dart. Performant, stable, feature-proof & modular.

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml)

##### package:media_kit is in active development & documentation is under construction... 🏗️

<hr>

<strong>Sponsored with 💖 by</strong>

<a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/28951144/204903234-4a64b63c-2fc2-4eef-be44-d287d27021e5.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/28951144/204903022-bbaa49ca-74c2-4a8f-a05d-af8314bfd2cc.svg">
    <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/204903022-bbaa49ca-74c2-4a8f-a05d-af8314bfd2cc.svg">
  </picture>
</a>

<h6>
  Rapidly ship in-app messaging with Stream's highly reliable chat infrastructure & feature-rich SDKs, including Flutter!
</h6>

<strong>
  <a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  Try the Flutter Chat tutorial
  </a>
</strong>

<br></br>

<a href="https://ottomatic.io/" target="_blank">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://user-images.githubusercontent.com/28951144/228648854-e5d7c557-ee92-47b2-a037-17b447873e1c.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://user-images.githubusercontent.com/28951144/228648844-f2a59ab1-12cd-4fee-bc8d-b2d332033c45.svg">
    <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/228648844-f2a59ab1-12cd-4fee-bc8d-b2d332033c45.svg">
  </picture>
</a>
<br></br>
<strong>
  <a href="https://ottomatic.io/" target="_blank">
  Clever Apps for Film Professionals
  </a>
</strong>

<hr>

![media_kit](https://user-images.githubusercontent.com/28951144/230397343-1c658eb1-5359-4005-89ed-f6c6237039eb.png)

## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit: ^0.0.4
  # For video rendering.
  media_kit_video: ^0.0.4
  # Enables support for higher number of concurrent instances. Optional.
  media_kit_native_event_loop: ^1.0.2
  # Pick based on your requirements / platform:
  media_kit_libs_windows_video: ^1.0.1          # Windows package for video (& audio) native libraries.
  media_kit_libs_ios_video: ^1.0.3              # iOS package for video (& audio) native libraries.
  media_kit_libs_macos_video: ^1.0.3            # macOS package for video (& audio) native libraries.
  media_kit_libs_linux: ^1.0.1                  # Linux dependency package.
```

## Platforms

| Platform  | Audio | Video |
| --------- | ----- | ----- |
| Windows   | Ready | Ready |
| GNU/Linux | Ready | Ready |
| macOS     | Ready | Ready |
| iOS       | Ready | Ready |
| Android   | [WIP](https://github.com/alexmercerind/media_kit/pull/100)   | [WIP](https://github.com/alexmercerind/media_kit/pull/100)   |
| Web       | WIP   | WIP   |

## Guide

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

#### Performance

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

_Windows 7 or higher is supported._

Everything ready. Just add **only one** of the following packages to your `pubspec.yaml` (if not already):

```yaml
dependencies:
  ...
  media_kit_libs_windows_video: ^1.0.1       # Windows package for video (& audio) native libraries.
  media_kit_libs_windows_audio: ^1.0.1       # Windows package for audio (only) native libraries.
```

### Linux

_Any modern Linux distribution is supported._

System shared libraries from distribution specific user-installed packages are used by-default. You can install these as follows.

#### Ubuntu / Debian

```bash
sudo apt install libmpv-dev mpv
```

#### Packaging

There are other ways to bundle these within your app package e.g. within Snap or Flatpak. Few examples:

- [Celluloid](https://github.com/celluloid-player/celluloid/blob/master/flatpak/io.github.celluloid_player.Celluloid.json)
- [VidCutter](https://github.com/ozmartian/vidcutter/tree/master/\_packaging)


Add following package to your `pubspec.yaml` (if not already).

```yaml
dependencies:
  ...
  media_kit_libs_linux: ^1.0.1                   # GNU/Linux dependency package.
```


### macOS

_macOS 11.0 or higher is supported._

Everything ready. Just add **only one** of the following packages to your `pubspec.yaml` (if not already).

```yaml
dependencies:
  ...
  media_kit_libs_macos_video: ^1.0.3             # macOS package for video native libraries.
```

During the build phase, the following warnings are not critical and cannot be silenced:

```log
#import "Headers/media_kit_video-Swift.h"
        ^
/path/to/media_kit/media_kit_test/build/macos/Build/Products/Debug/media_kit_video/media_kit_video.framework/Headers/media_kit_video-Swift.h:270:31: warning: 'objc_ownership' only applies to Objective-C object or block pointer types; type here is 'CVPixelBufferRef' (aka 'struct __CVBuffer *')
- (CVPixelBufferRef _Nullable __unsafe_unretained)copyPixelBuffer SWIFT_WARN_UNUSED_RESULT;
```

```log
# 1 "<command line>" 1
 ^
<command line>:20:9: warning: 'POD_CONFIGURATION_DEBUG' macro redefined
#define POD_CONFIGURATION_DEBUG 1 DEBUG=1 
        ^
#define POD_CONFIGURATION_DEBUG 1
        ^
```

### iOS

_iOS 13.0 or higher is supported._

Everything ready. Just add **only one** of the following packages to your `pubspec.yaml` (if not already):

```yaml
dependencies:
  media_kit_libs_ios_video: ^1.0.3              # iOS package for video native libraries.
```

## Goals

[package:media_kit](https://github.com/alexmercerind/media_kit) is a library for Flutter & Dart which **provides audio & video playback**.

- **Strong:** Supports _most_ audio & video codecs.
- **Performant:**
  - Handles multiple FHD videos flawlessly.
  - Rendering is GPU powered (hardware accelerated).
  - 4K / 8K 60 FPS is supported.
- **Stable:** Implementation is well tested & used across number of intensive media playback related apps.
- **Feature Proof:** A simple usage API offering large number of features to target multitude of apps.
- **Modular:** Project is split into number of packages for reducing bundle size.
- **Cross Platform**: Implementation works on all platforms supported by Flutter & Dart:
  - Windows
  - GNU/Linux
  - macOS
  - iOS
  - ~~Android~~ [WIP]
  - ~~Web~~ [WIP]
- **Flexible Architecture:**
  - Major part of implementation (80%+) is in 100% Dart (using [FFI](https://dart.dev/guides/libraries/c-interop)) & shared across platforms.
    - Makes behavior of library same & more predictable across platforms.
    - Makes development & implementation of new features easier & faster.
    - Avoids separate maintenance of native implementation for each platform.
  - Only video embedding code is platform specific & part of separate package.
  - Learn more: [Architecture](https://github.com/alexmercerind/media_kit#architecture), [Implementation](https://github.com/alexmercerind/media_kit#implementation).

The project aims to meet demands of the community, this includes:
1. Holding accountability.
2. Ensuring timely maintenance.

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
