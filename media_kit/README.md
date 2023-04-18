# [package:media_kit](https://github.com/alexmercerind/media_kit)

A complete video & audio playback library for Flutter & Dart. Performant, stable, feature-proof & modular.

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/alexmercerind/media_kit/actions/workflows/ci.yml)

<hr>

<strong>Sponsored with 💖 by</strong>

<a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/204903022-bbaa49ca-74c2-4a8f-a05d-af8314bfd2cc.svg">
</a>
<br></br>
<strong>
  <a href="https://getstream.io/chat/sdk/flutter/?utm_source=alexmercerind_dart&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=alexmercerind_December2022_FlutterSDK_klmh22" target="_blank">
  Try the Flutter Chat tutorial
  </a>
</strong>

<br></br>

<a href="https://ottomatic.io/" target="_blank">
  <img alt="Stream Chat" width="300" height="auto" src="https://user-images.githubusercontent.com/28951144/228648844-f2a59ab1-12cd-4fee-bc8d-b2d332033c45.svg">
</a>
<br></br>
<strong>
  <a href="https://ottomatic.io/" target="_blank">
  Clever Apps for Film Professionals
  </a>
</strong>

## Installation

[package:media_kit](https://github.com/alexmercerind/media_kit) is split into number of packages to improve modularity & reduce bundle size.

#### For apps that need video playback:

```yaml
dependencies:
  media_kit: ^0.0.5                              # Primary package.
  
  media_kit_video: ^0.0.5                        # For video rendering.
  
  media_kit_native_event_loop: ^1.0.3            # Support for higher number of concurrent instances & better performance.
  
  media_kit_libs_windows_video: ^1.0.2           # Windows package for video native libraries.
  media_kit_libs_android_video: ^1.0.0           # Android package for video native libraries.
  media_kit_libs_macos_video: ^1.0.4             # macOS package for video native libraries.
  media_kit_libs_ios_video: ^1.0.4               # iOS package for video native libraries.
  media_kit_libs_linux: ^1.0.2                   # GNU/Linux dependency package.
```

#### For apps that need audio playback:

```yaml
dependencies:
  media_kit: ^0.0.5                              # Primary package.
  
  media_kit_native_event_loop: ^1.0.2            # Support for higher number of concurrent instances & better performance.
  
  media_kit_libs_windows_audio: ^1.0.2           # Windows package for audio native libraries.
  media_kit_libs_android_audio: ^1.0.0           # Android package for audio native libraries.
  media_kit_libs_macos_audio: ^1.0.4             # macOS package for audio native libraries.
  media_kit_libs_ios_audio: ^1.0.4               # iOS package for audio native libraries.
  media_kit_libs_linux: ^1.0.2                   # GNU/Linux dependency package.
```

**Notes:**

- If app needs both video & audio playback, select video playback libraries.
- media_kit_libs_*** packages may be omitted depending upon the platform your app targets. 

## Platforms

| Platform | Video | Audio | Notes | Demo |
| -------- | ----- | ----- | ----- | ---- |
| Android     | ✅    | ✅    | Android 5.0 or above.              | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_android-arm64-v8a.apk) |
| iOS         | ✅    | ✅    | iOS 13 or above.                   | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_ios_arm64.7z)          |
| macOS       | ✅    | ✅    | macOS 11 or above.                 | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_macos_universal.7z)    |
| Windows     | ✅    | ✅    | Windows 7 or above.                | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_win32_x64.7z)          |
| GNU/Linux   | ✅    | ✅    | Any modern GNU/Linux distribution. | [Download](https://github.com/alexmercerind/media_kit/releases/download/media_kit-v0.0.5/media_kit_test_linux_x64.7z)          |
| Web         | 🚧    | 🚧    | [WIP](https://github.com/alexmercerind/media_kit/pull/128)                                | [WIP](https://github.com/alexmercerind/media_kit/pull/128)              |

<table>
  <tr>
    <td>
      Android
    </td>
    <td>
      iOS
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696332-37d54a33-9f8b-44df-a564-3420c74eb4da.jpg" height="400" alt="Android"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696349-6bad4f2b-439b-43bb-9ced-e05cd52b1477.jpg" height="400" alt="iOS"></img>
    </td>
</table>

<table>
  <tr>
    <td>
      macOS
    </td>
    <td>
      Windows
    </td>
    <td>
      GNU/Linux
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696378-5c8f76a6-d0a5-4215-8c4f-5a76957e5692.jpg" height="140" width="248.8" alt="macOS"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696391-c2577912-21c7-4a63-ad7c-37ded5cb2973.jpg" height="140" width="248.8" alt="Windows"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/232696361-57fa500a-1c24-4e5e-9152-a03bd5b7cfa6.jpg" height="140" width="248.8" alt="GNU/Linux"></img>
    </td>
</table>

## Guide

### TL;DR

A quick usage tutorial.

~~For detailed overview & guide to number of features in the library, please visit the [documentation](#).~~ WIP

#### 1. Initialize the library

```dart
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}
```

#### 2. Create a player to play & control an video/audio source with it

```dart
import 'package:media_kit/media_kit.dart';

/// Create a [Player] instance for video or audio playback.

final Player player = Player();

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

/// Open a playable [Media] or [Playlist].

await player.open(Media('file:///C:/Users/Hitesh/Music/Sample.mp3'));
await player.open(Media('file:///C:/Users/Hitesh/Video/Sample.mkv'));
await player.open(Media('rtsp://www.example.com/live'));
await player.open(Media('asset:///videos/bee.mp4'));
await player.open(
  Playlist(
    [
      Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373709-603a7a89-2105-4e1b-a5a5-a6c3567c9a59.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373716-76da0a4e-225a-44e4-9ee7-3e9006dbc3e3.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373718-86ce5e1d-d195-45d5-baa6-ef94041d0b90.mp4'),
      Media('https://user-images.githubusercontent.com/28951144/229373720-14d69157-1a56-4a78-a2f4-d7a134d7c3e9.mp4'),
    ],
  ),
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

#### 3. Render video output

GPU powered (hardware accelerated), automatically fallbacks to S/W rendering based on system.

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
      /// Play any media source.
      await player.open(Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4'));
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

## Goals

[package:media_kit](https://github.com/alexmercerind/media_kit) is a library for Flutter & Dart which **provides video & audio playback**.

- **Strong:** Supports _most_ video & audio codecs.
- **Performant:**
  - Handles multiple FHD videos flawlessly.
  - Rendering is GPU powered (hardware accelerated).
  - 4K / 8K 60 FPS is supported.
- **Stable:** Implementation is well tested & used across number of intensive media playback related apps.
- **Feature Proof:** A simple usage API while offering large number of features to target multitude of apps.
- **Modular:** Project is split into number of packages for reducing bundle size.
- **Cross Platform**: Implementation works on all platforms supported by Flutter & Dart:
  - Android
  - iOS
  - macOS
  - Windows
  - GNU/Linux
  - ~~Web~~ WIP
- **Flexible Architecture:**
  - Major part of implementation (80%+) is in 100% Dart ([FFI](https://dart.dev/guides/libraries/c-interop)) & shared across platforms.
    - Makes behavior of library same & more predictable across platforms.
    - Makes development & implementation of new features easier & faster.
    - Avoids separate maintenance of native implementation for each platform.
  - Only video embedding code is platform specific & part of separate package.

You may see project's [architecture](https://github.com/alexmercerind/media_kit#architecture) & [implementation](https://github.com/alexmercerind/media_kit#implementation) details for further information.

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

## Notes

### GNU/Linux

System shared libraries from distribution specific user-installed packages are used by-default. You can install these as follows:

#### Ubuntu/Debian

```bash
sudo apt install libmpv-dev mpv
```

#### Packaging

There are other ways to bundle these within your app package e.g. within Snap or Flatpak. Few examples:

- [Celluloid](https://github.com/celluloid-player/celluloid/blob/master/flatpak/io.github.celluloid_player.Celluloid.json)
- [VidCutter](https://github.com/ozmartian/vidcutter/tree/master/\_packaging)

### macOS

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

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
