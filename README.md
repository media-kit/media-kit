## 概述

这是 [media-kit](https://github.com/media-kit/media-kit) 的一个分支。

1. Linux 平台捆绑预构建 libmpv2.so 以摆脱对系统 mpv 的依赖。

2. windows 平台原生支持 D3D11 渲染器，支持零拷贝硬件加速渲染，并摆脱对 ANGLE 的依赖。

3. 合并来自 [avbuild](https://github.com/wang-bin/avbuild) 的 ffmpeg 树外补丁。可以播放原版 [media-kit](https://github.com/media-kit/media-kit) 无法播放, 但 [video_player](https://pub.dev/packages/video_player) 可以播放的非标准视频流。

4. 更新的 mpv 版本并优化二进制大小。

## 使用

在 pubspec.yaml 中添加
```
dependencies:
  media_kit:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./media_kit
  media_kit_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./media_kit_video
  media_kit_libs_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/universal/media_kit_libs_video

dependency_overrides:
  media_kit:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./media_kit
  media_kit_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./media_kit_video
  media_kit_libs_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/universal/media_kit_libs_video
  media_kit_libs_linux:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/linux/media_kit_libs_linux
  media_kit_libs_ios_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/ios/media_kit_libs_ios_video
  media_kit_libs_android_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/android/media_kit_libs_android_video
  media_kit_libs_windows_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/windows/media_kit_libs_windows_video
  media_kit_libs_macos_video:
    git:
      url: https://github.com/Predidit/media-kit.git
      ref: main
      path: ./libs/macos/media_kit_libs_macos_video
```