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
- feat: `aspectRatio` parameter for `Video` widget.

## 0.0.1

- Initial release.
- Windows support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + ANGLE + DirectX 11
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
- GNU/Linux support:
  - Hardware: MPV_RENDER_API_TYPE_OPENGL + GDK/GL
  - Software: MPV_RENDER_API_TYPE_SW + pixel buffer
