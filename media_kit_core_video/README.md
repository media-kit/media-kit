# [package:media_kit_core_video](https://github.com/alexmercerind/media_kit)

Native implementation for video playback in [package:media_kit](https://pub.dev/packages/media_kit) & relevant Flutter Widgets.

## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit_core_video: ^0.0.1
```

**NOTE:** This is a Flutter package. It will not work with Dart-only projects.

## Platforms

- [x] Windows
- [x] Linux
- [ ] macOS
- [ ] Android
- [ ] iOS

## Support

If you find [package:media_kit](https://github.com/alexmercerind/media_kit) package(s) useful or want to support future development, please consider supporting me. It's a very tedious process to write code, document, maintain & provide support for free. Since this is first of a kind project, it takes a lot of time to experiment & develop.

- [GitHub Sponsors](https://github.com/sponsors/alexmercerind)
- [PayPal](https://paypal.me/alexmercerind)

## Implementation

### Windows

[libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) from [mpv Media Player](https://mpv.io/) is used for leveraging video playback.

- [libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) gives access to C API for rendering hardware-accelerated video output using OpenGL. See: [render.h](https://github.com/mpv-player/mpv/blob/master/libmpv/render.h) & [render_gl.h](https://github.com/mpv-player/mpv/blob/master/libmpv/render_gl.h).
- Flutter recently added ability for Windows to [render Direct3D `ID3D11Texture2D` textures](https://github.com/flutter/engine/pull/26840).

The two APIs above are hardware accelerated i.e. GPU backed buffers are used. **This is performant approach, easily capable for rendering 4K 60 FPS videos**, rest depends on the hardware. Since [libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) API is OpenGL based & the Texture API in Flutter is Direct3D based, [ANGLE (Almost Native Graphics Layer Engine)](https://github.com/google/angle) is used for interop, which automatically translates the OpenGL ES calls into Direct3D.

This hardware accelerated video output requires DirectX 11 or higher. Most Windows systems with either integrated or discrete GPUs should support this already. On systems where Direct3D fails to load due to missing graphics drivers or unsupported feature-level or DirectX version etc. a fallback pixel-buffer based software renderer is used. This means that video is rendered by CPU & every frame is copied back to the RAM. This will cause some redundant load on the CPU, result in decreased battery life & may not play higher resolution videos properly. However, it works.

You can visit my [experimentation repository](https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-Direct3D-Interop) to see a minimal example showing OpenGL ES rendering inside Flutter Windows.

### Linux

[libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) from [mpv Media Player](https://mpv.io/) is used for leveraging video playback. System shared libraries from distribution specific user-installed packages are used by-default. On Ubuntu / Debian based systems, you can install these using:

**NOTE:** This package also bundles specific shared libraries & dependencies.

```bash
sudo apt install mpv libmpv-dev
```

On Flutter Linux, [both OpenGL (hardware accelerated) & Pixel Buffer (software) APIs](https://github.com/flutter/engine/pull/24916) are available for rendering on Texture widget.

## License

Copyright © 2022, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.

# [package:media_kit_core_video](https://github.com/alexmercerind/media_kit)

Native implementation for video playback in [package:media_kit](https://pub.dev/packages/media_kit) & relevant Flutter Widget(s).

## Installation

Add in your `pubspec.yaml`:

```yaml
dependencies:
  media_kit_core_video: ^0.0.1
```

**NOTE:** This is a Flutter package. It will not work with Dart-only projects.

## Platforms

- [x] Windows
- [x] Linux
- [ ] macOS
- [ ] Android
- [ ] iOS

## Support

If you find [package:media_kit](https://github.com/alexmercerind/media_kit) package(s) useful or want to support future development, please consider supporting me. It's a very tedious process to write code, document, maintain & provide support for free. Since this is first of a kind project, it takes a lot of time to experiment & develop.

- [GitHub Sponsors](https://github.com/sponsors/alexmercerind)
- [PayPal](https://paypal.me/alexmercerind)

## Implementation

### Windows

[libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) from [mpv Media Player](https://mpv.io/) is used for leveraging video playback.

- [libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) gives access to C API for rendering hardware-accelerated video output using OpenGL. See: [render.h](https://github.com/mpv-player/mpv/blob/master/libmpv/render.h) & [render_gl.h](https://github.com/mpv-player/mpv/blob/master/libmpv/render_gl.h).
- Flutter recently added ability for Windows to [render Direct3D `ID3D11Texture2D` textures](https://github.com/flutter/engine/pull/26840).

The two APIs above are hardware accelerated i.e. GPU backed buffers are used. **This is performant approach, easily capable for rendering 4K 60 FPS videos**, rest depends on the hardware. Since [libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) API is OpenGL based & the Texture API in Flutter is Direct3D based, [ANGLE (Almost Native Graphics Layer Engine)](https://github.com/google/angle) is used for interop, which automatically translates the OpenGL ES calls into Direct3D.

This hardware accelerated video output requires DirectX 11 or higher. Most Windows systems with either integrated or discrete GPUs should support this already. On systems where Direct3D fails to load due to missing graphics drivers or unsupported feature-level or DirectX version etc. a fallback pixel-buffer based software renderer is used. This means that video is rendered by CPU & every frame is copied back to the RAM. This will cause some redundant load on the CPU, result in decreased battery life & may not play higher resolution videos properly. However, it works.

You can visit my [experimentation repository](https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-Direct3D-Interop) to see a minimal example showing OpenGL ES rendering inside Flutter Windows.

### Linux

[libmpv](https://github.com/mpv-player/mpv/tree/master/libmpv) from [mpv Media Player](https://mpv.io/) is used for leveraging video playback. System shared libraries from distribution specific user-installed packages are used by-default. On Ubuntu / Debian based systems, you can install these using:

**NOTE:** This package also bundles specific shared libraries & dependencies.

```bash
sudo apt install mpv libmpv-dev
```

On Flutter Linux, [both OpenGL (hardware accelerated) & Pixel Buffer (software) APIs](https://github.com/flutter/engine/pull/24916) are available for rendering on Texture widget.

## License

Copyright © 2022, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

This project & the work under this repository is governed by MIT license that can be found in the [LICENSE](./LICENSE) file.
