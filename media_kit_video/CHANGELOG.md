## 1.1.0

- feat: `SubtitleView`, `SubtitleViewConfiguration`
- feat: `shiftSubtitlesOnControlsVisibilityChange` in `MaterialVideoControls` & `MaterialDesktopVideoControls`
- feat: apply rotation from metadata to video output
- feat: improve wakelock behavior
- feat: `pauseUponEnteringBackgroundMode`
- fix: `bufferingIndicatorBuilder` padding in `MaterialVideoControls` & `MaterialDesktopVideoControls`
- fix(windows): maintain aspect ratio in s/w rendering pixel-buffer size clamping
- fix(linux): maintain aspect ratio in s/w rendering pixel-buffer size clamping
- perf(android): use `hwdec=mediacodec` w/ `enableHardwareAcceleration`
- deps: migrate [`package:wakelock_plus`](https://pub.dev/packages/wakelock_plus)

## 1.0.2

- fix(video/macos): fix fullscreen support

## 1.0.1

- fix: synchronize `VideoController` constructor
- fix: `fullscreen` video controls theme data not being applied

## 1.0.0

- feat: web support
- feat: fullscreen API
- feat: acquire wakelock
- feat: support for AGP 8.0
- feat: pre-built video controls
- feat: `controls` argument in `Video` widget
- feat: `AdaptiveVideoControls`, `MaterialVideoControls`, `MaterialDesktopVideoControls` & `NoVideoControls`

## 0.0.12

- fix(android): improve `Texture` resize handling

## 0.0.11

- fix(android): improve `Texture` resize handling

## 0.0.10

- feat: `VideoControllerConfiguration`
- feat: `VideoController.waitUntilFirstFrameRendered`
- refactor: clean-up package structure
- refactor: remove `VideoController.dispose`
- refactor: `VideoController.create` -> `VideoController` constructor
- fix(android): add `av1` to `hwdec-codecs`
- fix(android): use `--vo=gpu` + `--hwdec=mediacodec-copy` /w `enableHardwareAcceleration`

## 0.0.9

- fix(android): revert to `--vo=mediacodec_embed` in `enableHardwareAcceleration`

## 0.0.8

- fix(android): subtitle rendering
- fix(android): video rendering inside emulators (#149)
- fix(android): video rendering with `enableHardwareAcceleration: false`

## 0.0.7

- fix(linux): VAAPI hardware acceleration
- perf(windows): `VideoOutput::Resize`: delete texture objects in background

## 0.0.6

- fix(windows): synchronize texture object deletion in on unregister _v.i.z_ `VideoOutput::Resize` or `VideoOutput::~VideoOutput`

## 0.0.5

- Android support
- feat: `VideoController.setSize`
- fix: set `vo` to `libmpv` before creating render context
- refactor: `VideoController.create` takes `Player` reference instead of `handle`

## 0.0.4

- fix: use `mkdir` instead of `.gitkeep`

## 0.0.3

- fix: add `.framework` & `.xcframework` for all libs

## 0.0.2

- macOS support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + pixel buffer + METAL
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
- iOS support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + pixel buffer
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
- fix(windows): use `TextureRegistrar::UnregisterTexture` release callback to free texture resources
- fix(windows): synchronize texture unregister & release on frame dimensions change
- feat: `aspectRatio` parameter for `Video` widget

## 0.0.1

- Initial release
- Windows support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + ANGLE + DirectX 11
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
- GNU/Linux support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + GDK/GL
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
