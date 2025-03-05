# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-03-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`media_kit` - `v1.2.0`](#media_kit---v120)
 - [`media_kit_libs_android_audio` - `v1.3.7`](#media_kit_libs_android_audio---v137)
 - [`media_kit_libs_android_video` - `v1.3.7`](#media_kit_libs_android_video---v137)
 - [`media_kit_libs_linux` - `v1.2.1`](#media_kit_libs_linux---v121)
 - [`media_kit_libs_windows_video` - `v1.0.11`](#media_kit_libs_windows_video---v1011)
 - [`media_kit_video` - `v1.3.0`](#media_kit_video---v130)
 - [`video_player_media_kit` - `v1.0.6`](#video_player_media_kit---v106)
 - [`media_kit_libs_audio` - `v1.0.6`](#media_kit_libs_audio---v106)
 - [`media_kit_libs_video` - `v1.0.6`](#media_kit_libs_video---v106)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `media_kit_libs_audio` - `v1.0.6`
 - `media_kit_libs_video` - `v1.0.6`

---

#### `media_kit` - `v1.2.0`

 - **REFACTOR**: InitializerNativeCallable & InitializerIsolate.
 - **REFACTOR**: migrate NativePlayer Initializer to NativeCallable.
 - **REFACTOR**: hook NativeReferenceHolder.
 - **REFACTOR**: TempFile.
 - **REFACTOR**: remove InitializerNativeEventLoop.
 - **PERF**: observe playlist-playing-pos instead of playlist.
 - **PERF**: use loadlist in NativePlayer.open.
 - **FIX**: increase retry count for flaky player subtitle test.
 - **FIX**: bump web to 1.1.0.
 - **FIX**: comment out unsupported headers on web.
 - **FIX**: proper function signature.
 - **FIX**: pass http headers to hls.js.
 - **FIX**: emit position in stop.
 - **FIX**: NativePlayer.remove.
 - **FIX**: player.stream.playlist in add/remove.
 - **FIX**: player-open-playable-playlist-start-end.
 - **FIX**: playlist emit.
 - **FIX**: emit playlist from open.
 - **FIX**: add more formats to FallbackBitrateHandler.
 - **FIX**: delete temporary file in `NativePlayer`.
 - **FIX**: video_player black screen.
 - **FIX**: handle incorrect encoding in toDartString.
 - **FIX**: catch observe property callback exception.
 - **FIX**: NativeReferenceHolder on 32-bit systems.
 - **FIX**: do not reset audioParams & audioBitrate in stop.
 - **FIX**: Initializer._callback.
 - **FIX**: supply callback to NativeReferenceHolder.
 - **FIX**(android): libass font support.
 - **FEAT**: PlayerConfiguration.async.
 - **FEAT**: NativeReferenceHolder.remove.
 - **FEAT**: NativeReferenceHolder.
 - **FEAT**: waitForInitialization.
 - **FEAT**: Add support for including libass subtitles in screenshots.

#### `media_kit_libs_android_audio` - `v1.3.7`

 - **FIX**: undefined variable.
 - **FIX**: check if is found before md5.
 - **FIX**: md5 check.
 - **FIX**: md5Matches.
 - **FIX**: new gradle logic for downloading.

#### `media_kit_libs_android_video` - `v1.3.7`

 - **FIX**: undefined variable.
 - **FIX**: check if is found before md5.
 - **FIX**: md5 check.
 - **FIX**: md5Matches.
 - **FIX**: new gradle logic for downloading.

#### `media_kit_libs_linux` - `v1.2.1`

 - **FIX**: correct minimum required CMake version.

#### `media_kit_libs_windows_video` - `v1.0.11`

 - **FIX**(windows): do not bundle MSVCP/UCRT DLLs.

#### `media_kit_video` - `v1.3.0`

 - **REFACTOR**: screen_brightness -> screen_brightness_platform_interface.
 - **REFACTOR**(android): simplify AndroidVideoController implementation.
 - **REFACTOR**(android): VideoOutput SurfaceTextureEntry -> SurfaceProducer migration.
 - **REFACTOR**: use setProperty API in NativeVideoController.
 - **FIX**: improve responsiveness of showing controls on mobile.
 - **FIX**: bump web to 1.1.0.
 - **FIX**: cast to JSObject.
 - **FIX**: not call super.didChangeAppLifecycleState(state);.
 - **FIX**: not call super.didChangeAppLifecycleState(state);.
 - **FIX**: wakelock print.
 - **FIX**: subtitles not shifting on controls show/hide.
 - **FIX**: set width/height from VideoParams in NativeVideoController.
 - **FIX**: seek inside onPointerMove.
 - **FIX**(windows): automatic IDXGIAdapter selection on windows 10 or greater.
 - **FIX**(android): waitUntilFirstFrameRenderedCompleter.
 - **FIX**(android): --hwdec=auto-safe as default.
 - **FIX**: dispose ValueNotifier(s) in PlatformVideoController.
 - **FIX**: fullscreen.
 - **FIX**: long press video speed reset issue.
 - **FIX**: wrong value in brightness builder callback.
 - **FIX**: Use a Scaffold as the outermost widget on fullscreen video pages.
 - **FEAT**: upgrade volume_controller dependency and refactor related code.
 - **FEAT**: seek on double tap custom duration support.

#### `video_player_media_kit` - `v1.0.6`

 - **FIX**: add null checks for uri and textureId in MediaKitVideoPlayer.
 - **FIX**: video_player black screen.

