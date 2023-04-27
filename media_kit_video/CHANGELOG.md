## 0.0.9

- fix(android): improve stability

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

- Initial release.
- Windows support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + ANGLE + DirectX 11
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
- GNU/Linux support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + GDK/GL
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
