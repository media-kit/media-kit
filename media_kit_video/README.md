# [package:media_kit_video](https://github.com/media-kit/media-kit)

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/media-kit/media-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/media-kit/media-kit/actions/workflows/ci.yml)

Native implementation for video playback in [package:media_kit](https://pub.dev/packages/media_kit).

## Picture-in-Picture

Declarative Picture-in-Picture is available on iOS 15+ and Android 8.0+ (API 26). Pass a `PipConfig` to `Video`:

```dart
Video(
  controller: videoController,
  pauseUponEnteringBackgroundMode: false,
  pip: const PipConfig(autoEnter: true),
  onPipEvent: (event) {
    // Optional: observe lifecycle + play/pause events.
  },
)
```

For imperative control use `videoController.pictureInPicture`:

```dart
await videoController.pictureInPicture.start(
  handle: await player.handle,
  videoSize: const Size(1280, 720),
);
await videoController.pictureInPicture.stop();
videoController.pictureInPicture.events.listen((event) {});
```

### Platform setup

**iOS** — enable the `audio` background mode in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Android** — mark the host Activity in `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:resizeableActivity="true"
    ... />
```

### Platform support

- Picture-in-Picture APIs are gated at runtime: iOS < 15 and Android < 26 silently no-op.
- Desktop (macOS/Linux/Windows) and web use a no-op implementation; `PipConfig` is ignored.
- Lifecycle events on Android 8.0–11 are limited; full event coverage requires API 31+.

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
