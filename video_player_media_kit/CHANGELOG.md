## 0.0.26

- media_kit windows version to 1.0.6
- media_kit linux version to 1.1.0

## 0.0.25

- set media_kit to 1.1.2+1 to avoid crash on launch

## 0.0.24

- updating media_kit to latest version
- removing ios and android video libs (to make them optional)

## 0.0.23

- using latest version of media_kit
- added throw errors in initVideoPlayerMediaKitIfNeeded

## 0.0.22

- fixing live errors

## 0.0.21

- fix web compilation

## 0.0.20

- upgrade media_kit to 1.1.0

## 0.0.19

- renaming VideoPlayer to VideoPlayerMediaKitWidget to avoid conflicts

## 0.0.18

- MediaKitTheme to customize fill color

## 0.0.17

- upgrade media_kit to 1.0.1

## 0.0.16

- Fixed seeking going to end of file

## 0.0.15

- Only log errors for now, until media_kit provides a better support for loading errors

## 0.0.14

- Fixes future already completed errors (at the end of videos)

## 0.0.13

- Dropping logLevel for MPVLogLevel
- Expose Errors to video events (Fixing errors not being caught)

## 0.0.12

- Used media_kit http headers

## 0.0.11

- Updated media_kit packages

## 0.0.10

- Updated media_kit packages
- Fixes playing on android

## 0.0.9

- Added set looping

## 0.0.8

- Updated media_kit and media_kit_video dependencies to newer versions (0.0.5 and 0.0.6, respectively).
- Updated media_kit_native_event_loop dependency to version 1.0.3, which provides better performance and support for a higher number of concurrent instances.
- Updated the version of the media_kit_libs_windows_video package to 1.0.2, which provides video native libraries for Windows.
- Updated the version of the media_kit_libs_macos_video package to 1.0.4, which provides video native libraries for macOS.
- Updated the version of the media_kit_libs_linux package to 1.0.2, which provides GNU/Linux dependency package.
- Updated the version of the media_kit_libs_ios_video package to 1.0.4, which provides video native libraries for iOS.
- Modified the code in video_player_media_kit_platform_ffi.dart to improve buffering behavior during video playback.
- Added instructions for using the media_kit_libs_android_video package to provide video native libraries for Android.
- initVideoPlayerMediaKitIfNeeded added androidUseMediaKit

## 0.0.7

- set demuxer-lavf-o -> protocol_whitelist=[file,tcp,tls,http,https] to fix m3u8 quality

## 0.0.6

- fix asset playing by adding asset:// if not added

## 0.0.5

- Added option to define logs level in initVideoPlayerMediaKitIfNeeded
- Updated media_kit and docs

## 0.0.4

- Updated readme and fixed macos and ios errors

## 0.0.3

- Reduce sdk limits

## 0.0.2

- Fixed buffering.
- Improved handling errors.
- Fixed wrong id

## 0.0.1

- initial release.
