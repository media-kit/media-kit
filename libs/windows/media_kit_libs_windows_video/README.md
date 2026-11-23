# [package:media_kit_libs_windows_video](https://github.com/media-kit/media-kit)

[![](https://img.shields.io/discord/1079685977523617792?color=33cd57&label=Discord&logo=discord&logoColor=discord)](https://discord.gg/h7qf2R9n57) [![Github Actions](https://github.com/media-kit/media-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/media-kit/media-kit/actions/workflows/ci.yml)

This package supplies libmpv for video and audio playback on Windows.

## Windows build

CMake selects the SDK archive for the Flutter target.

| Flutter target | SDK archive |
| --- | --- |
| `windows-x64` | `mpv-dev-x86_64-<date>-git-<revision>.7z` |
| `windows-arm64` | `mpv-dev-aarch64-<date>-git-<revision>.7z` |

CMake checks the SHA-256 checksum before it extracts the archive.
The video plugin uses the headers in `include/mpv` to compile.
The linker uses `libmpv.dll.a`.
Flutter places `libmpv-2.dll` beside the application executable.

See the [libmpv releases](https://github.com/media-kit/libmpv-win32-video-cmake/releases) for the SDK archives.

## License

Copyright © 2021 & onwards, Hitesh Kumar Saini <<saini123hitesh@gmail.com>>

The [MIT license](./LICENSE) covers this package.
