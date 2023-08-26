## Video Player Cross Platform

<a target="blank" href="https://pub.dev/packages/video_player_media_kit"><img src="https://img.shields.io/pub/v/video_player_media_kit?include_prereleases&style=flat-square"/></a>
<img src="https://img.shields.io/github/last-commit/zezo357/video_player_media_kit/master?style=flat-square"/>
<img src="https://img.shields.io/github/license/zezo357/video_player_media_kit?style=flat-square"/>

Video Player Cross Platform is a platform interface for video player using media_kit to work on Windows and Linux and macos. This interface allows you to play videos seamlessly in your flutter application.

Note: this package allows video_player to work across platforms

- [video_player](https://pub.dev/packages/video_player) for Android, iOS, and web.
- [media_kit](https://pub.dev/packages/media_kit) for desktop platforms.

## How to use

To use Video Player Cross Platform in your application, follow the steps below:

1. Setup

### Windows

Everything ready.

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

## Note: macos is not tested (if you have any problems open an issue)

### macOS

Everything ready.

The minimum supported macOS version is 11.0,set MACOSX_DEPLOYMENT_TARGET = 11.0 `macos\Runner.xcodeproj\project.pbxproj`

Also, during the build phase, the following warnings are not critical and cannot be silenced:

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

### iOS (replace original video_player with media_kit one)

1. The minimum supported iOS version is 13.0,set IPHONEOS_DEPLOYMENT_TARGET to 13.0 in `ios\Runner.xcodeproj\project.pbxproj`
2. Just add this package in case you set iosUseMediaKit to true in initVideoPlayerMediaKitIfNeeded

```yaml
dependencies:
  ...
  media_kit_libs_ios_video: ^1.1.1                # iOS package for video native libraries.
```

### Android (replace original video_player with media_kit one)

1. Just add this package in case you set androidUseMediaKit to true in initVideoPlayerMediaKitIfNeeded

```yaml
dependencies:
  ...
  media_kit_libs_android_video: ^1.3.2           # Android package for video native libraries.
```

1. Add the Video Player Cross Platform dependency in your `pubspec.yaml` file:

```
dependencies:
  video_player_media_kit: ^0.0.20
```

3.  Import the package in your Dart code

```
import 'package:video_player_dart_vlc/video_player_media_kit.dart';
```

4.  Initialize the Video Player Cross Platform interface in the main function of your app

```
void main() {
  initVideoPlayerMediaKitIfNeeded(); //parameter iosUseMediaKit can be used to make ios use media_kit instead of video_player
  runApp(MyApp());
}
```

now video_player will work on any platform.
