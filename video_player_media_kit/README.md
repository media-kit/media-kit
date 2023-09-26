# [package:video_player_media_kit](https://github.com/media-kit/media-kit)

#### package:video_player support for all platforms, based on package:media_kit.

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/media-kit/media-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/media-kit/media-kit/actions/workflows/ci.yml)

After a single line initialization, you can normally use [package:video_player](https://pub.dev/packages/video_player) & enjoy:
- Support for all platforms _i.e_ Android, iOS, macOS, Windows, GNU/Linux & web.
- Support for more video/audio formats & codecs.
- ...

package:video_player_media_kit allows [package:video_player](https://pub.dev/packages/video_player) to use [package:media_kit](https://pub.dev/packages/media_kit) as a backend.

<table>
  <tr>
    <td>
      TODO:
    </td>
    <td>
      <img height="320" src="https://github.com/zezo357/media_kit/assets/28951144/b0677b4a-7f2b-476d-98b8-d72e3218f749">
    </td>
    <td>
      TODO:
    </td>
    
  </tr>
  <tr>
    <td>
      package:video_player on macOS
    </td>
    <td>
      package:video_player on Windows
    </td>
    <td>
      package:video_player on GNU/Linux
    </td>
  </tr>
</table>

## Installation

```yaml
dependencies:
  video_player_media_kit: ^1.0.0

  # NOTE:
  # It is not necessary to select all.
  # Select based on your usage:
  media_kit_libs_android_audio: any
  media_kit_libs_ios_audio: any
  media_kit_libs_macos_audio: any
  media_kit_libs_windows_audio: any
  media_kit_libs_linux: any
```

## TL;DR

A quick usage example.

```dart
void main() {
  VideoPlayerMediaKit.ensureInitialized(
    android: true,          // default: false    -    dependency: media_kit_libs_android_audio
    iOS: true,              // default: false    -    dependency: media_kit_libs_ios_audio
    macOS: true,            // default: false    -    dependency: media_kit_libs_macos_audio
    windows: true,          // default: false    -    dependency: media_kit_libs_windows_audio
    linux: true,            // default: false    -    dependency: media_kit_libs_linux
  );

  // USE package:video_player NORMALLY!
  runApp(MyApp());
}
```

**Notes:**

- The corresponding `media_kit_libs_***` package for a platform must be added if enabled in `VideoPlayerMediaKit.ensureInitialized`.

## License

Copyright © 2023 & onwards, Abdelaziz Mahdy <abdelaziz.h.mahdy@gmail.com>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
