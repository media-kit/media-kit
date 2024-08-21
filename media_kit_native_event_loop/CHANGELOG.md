## 1.0.9
- fix windows crash by @Airyzz [#900](https://github.com/media-kit/media-kit/pull/900)

## 1.0.8

- fix(windows): graceful process exit

## 1.0.7

- build(darwin): bump `mpv` headers to `0.36.0`
- build(darwin): use symlinks for `FRAMEWORK_SEARCH_PATHS`, `media_kit_libs_*** >= 1.1.0`

## 1.0.6

- fix(windows): possible crash on hot-restart

## 1.0.5

- fix(windows): rare "mutex destroyed while busy" error
- fix(macos): occasional EXC_BAD_ACCESS on application terminate

## 1.0.4

- feat: `MediaKitEventLoopHandler::Dispose`
- perf: switch to `std::condition_variable`(s) for synchronization

## 1.0.3

- feat: make package optional during build

## 1.0.2

- fix: add `.framework` & `.xcframework` for all libs

## 1.0.1

- macOS support
- iOS support
- fix: broken hot restart

## 1.0.0

- Initial release
- Windows support
- Linux support
