## 概述

这是 [media-kit](https://github.com/media-kit/media-kit) 的一个分支。

主要目标为在 Linux 平台上使用与构建的 libmpv2.so 而不是系统mvp。

此外本分支合并了来自 [avbuild](https://github.com/wang-bin/avbuild) 的 ffmpeg 树外补丁。可以播放原版 [media-kit](https://github.com/media-kit/media-kit) 无法播放, 但 [video_player](https://pub.dev/packages/video_player) 可以播放的非标准视频流。

## 使用

在 linux/CmakeLists.txt 中添加
```
# add runpath, shared libs of a release bundle is in lib dir, plugin must add $ORIGIN to runpath to find libmpv
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,-z,origin -Wl,-rpath,\\$ORIGIN")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--enable-new-dtags -Wl,-z,origin -Wl,-rpath,\\$ORIGIN")
```

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