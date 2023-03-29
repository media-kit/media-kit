## 0.0.2

- macOS support:
  - Video (& audio): [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2) + [`media_kit_libs_macos_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_macos_video/versions/1.0.0)
- iOS support:
  - Video (& audio): [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2) + [`media_kit_libs_ios_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_ios_video/versions/1.0.0)
- feat: draw first frame upon `Player.open` before `Player.play` (#69)
- feat: `Player.open` now accepts `Playable` i.e. `Media` or `Playlist`
- feat: access `Player` logs from internal backend e.g. libmpv
  - `PlayerLogs`: class
  - `Player.streams.logs`: logs as `Stream<PlayerLogs>`
- fix: improve internal playlist handling & management
- feat: audio output device selection & enumeration
  - `Player.setAudioDevice`: method
  - `AudioDevice`: class
  - `AudioDevice.auto`: factory constructor
  - `Player.state.audioDevice`: currently selected audio device as `AudioDevice`
  - `Player.streams.audioDevice`: currently selected audio device as `Stream<AudioDevice>`
  - `Player.state.audioDevices`: currently available audio device(s) as `List<AudioDevice>`
  - `Player.streams.audioDevices`: currently available audio device(s) as `Stream<List<AudioDevice>>`
- feat: video, audio & subtitle track selection & enumeration (#54)
  - `Player.selectVideoTrack`: method
  - `Player.selectAudioTrack`: method
  - `Player.selectSubtitleTrack`: method
  - `VideoTrack`: class
  - `AudioTrack`: class
  - `SubtitleTrack`: class
  - `VideoTrack.auto`: factory constructor
  - `VideoTrack.no`: factory constructor
  - `AudioTrack.auto`: factory constructor
  - `AudioTrack.no`: factory constructor
  - `SubtitleTrack.auto`: factory constructor
  - `SubtitleTrack.no`: factory constructor
  - `Player.state.track.video`: currently selected video track as `VideoTrack`
  - `Player.streams.track.video`: currently selected video track as `Stream<VideoTrack>`
  - `Player.state.track.audio`: currently selected audio track as `AudioTrack`
  - `Player.streams.track.audio`: currently selected audio track as `Stream<AudioTrack>`
  - `Player.state.track.subtitle`: currently selected subtitle track as `SubtitleTrack`
  - `Player.streams.track.subtitle`: currently selected subtitle track as `Stream<SubtitleTrack>`
  - `Player.state.tracks.video`: currently available video track(s) as `List<VideoTrack>`
  - `Player.streams.tracks.video`: currently available video track(s) as `Stream<List<VideoTrack>>`
  - `Player.state.tracks.audio`: currently available audio track(s) as `List<AudioTrack>`
  - `Player.streams.tracks.audio`: currently available audio track(s) as `Stream<List<AudioTrack>>`
  - `Player.state.tracks.subtitle`: currently available subtitle track(s) as `List<SubtitleTrack>`
  - `Player.streams.tracks.subtitle`: currently available subtitle track(s) as `Stream<List<SubtitleTrack>>`
- refactor: rename `Player.volume` setter to `Player.setVolume`
- refactor: rename `Player.rate` setter to `Player.setRate`
- refactor: rename `Player.pitch` setter to `Player.setPitch`
- refactor: rename `Player.shuffle` setter to `Player.setShuffle`
- refactor: rename `Player.state.isPlaying` to `Player.state.playing`
- refactor: rename `Player.state.isPaused` to `Player.state.paused`
- refactor: rename `Player.state.isCompleted` to `Player.state.completed`
- refactor: rename `Player.state.isBuffering` to `Player.state.buffering`
- refactor: rename `Player.streams.isPlaying` to `Player.streams.playing`
- refactor: rename `Player.streams.isPaused` to `Player.streams.paused`
- refactor: rename `Player.streams.isCompleted` to `Player.streams.completed`
- refactor: rename `Player.streams.isBuffering` to `Player.streams.buffering`

#### Recommended sub-package versions

- [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2)
- [`media_kit_native_event_loop: ^1.0.1`](https://pub.dev/packages/media_kit_native_event_loop/versions/1.0.1)
- [`media_kit_libs_windows_video: ^1.0.1`](https://pub.dev/packages/media_kit_libs_windows_video/versions/1.0.1)
- [`media_kit_libs_windows_audio: ^1.0.1`](https://pub.dev/packages/media_kit_libs_windows_audio/versions/1.0.1)
- [`media_kit_libs_linux: ^1.0.1`](https://pub.dev/packages/media_kit_libs_linux/versions/1.0.1)
- [`media_kit_libs_macos_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_macos_video/versions/1.0.0)
- [`media_kit_libs_ios_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_ios_video/versions/1.0.0)

## 0.0.1

- Initial release.
- Windows support
  - Video (& audio): [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2) + [`media_kit_libs_windows_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_windows_video/versions/1.0.0)
  - Audio (only): [`media_kit_libs_windows_audio: ^1.0.1`](https://pub.dev/packages/media_kit_libs_windows_audio/versions/1.0.1)
- GNU/Linux support
  - Video (& audio): [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2) + [`media_kit_libs_linux: ^1.0.0`](https://pub.dev/packages/media_kit_libs_linux/versions/1.0.0)
  - Audio (only): [`media_kit_libs_linux: ^1.0.0`](https://pub.dev/packages/media_kit_libs_linux/versions/1.0.0)

#### Recommended sub-package versions

- [`media_kit_video: ^0.0.2`](https://pub.dev/packages/media_kit_video/versions/0.0.2)
- [`media_kit_native_event_loop: ^1.0.1`](https://pub.dev/packages/media_kit_native_event_loop/versions/1.0.1)
- [`media_kit_libs_windows_video: ^1.0.1`](https://pub.dev/packages/media_kit_libs_windows_video/versions/1.0.1)
- [`media_kit_libs_windows_audio: ^1.0.1`](https://pub.dev/packages/media_kit_libs_windows_audio/versions/1.0.1)
- [`media_kit_libs_linux: ^1.0.1`](https://pub.dev/packages/media_kit_libs_linux/versions/1.0.1)
- [`media_kit_libs_macos_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_macos_video/versions/1.0.0)
- [`media_kit_libs_ios_video: ^1.0.0`](https://pub.dev/packages/media_kit_libs_ios_video/versions/1.0.0)
