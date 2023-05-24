## 0.0.8

- fix: `Player.dispose` event loop clean-up
- refactor: `Player` implementation clean-up
- feat: `Initializer.dispose`
  - feat: `InitializerIsolate.dispose`
  - feat: `InitializerNativeEventLoop.dispose`
- feat: `PlatformPlayer.waitForVideoControllerInitializationIfAttached`
- feat: HTTP headers support in `Media`

## 0.0.7+1

- docs: document updated `media_kit_libs_android_video` and `media_kit_libs_android_audio`

## 0.0.7

- fix: `MediaKit.ensureInitialized` not passing optional `libmpv` argument

## 0.0.6

- feat: synchronize `Player` methods
- refactor: improve `Playlist` handling in `Player`
- refactor: improve handling of `playlist`, `audioBitrate` & `audioParams` states/events

## 0.0.5+2

- docs: document updated `media_kit_video` & `media_kit_libs_windows_audio`

## 0.0.5+1

- docs: document updated `media_kit_video`

## 0.0.5

- Android support
- feat: video output width & height states/events:
  - `Player.state.width`: currently playing video's width as `int`
  - `Player.streams.width`: currently playing video's width as `Stream<int>`
  - `Player.state.height`: currently playing video's height as `int`
  - `Player.streams.height`: currently playing video's height as `Stream<int>`
- feat(refactor): entry point
  - `MediaKit.ensureInitialized`
- feat: media stream buffer state/event:
  - `Player.state.buffer`: currently buffered duration of the media stream as `Duration`
  - `Player.streams.buffer`: currently buffered duration of the media stream as `Stream<Duration>`
- perf: limit demuxer cache size to 32 MB by default
- fix: HTTPS m3u8 file loading
- fix: asset names with special characters
- feat: `protocolWhitelist` in `PlayerConfiguration` for whitelisting protocols
- feat: `bufferSize` in `PlayerConfiguration` for setting demuxer cache size

## 0.0.4+1

- docs(fix): images on pub.dev

## 0.0.4

- fix: opening `Playlist` (with `index` > 0) causes index to be treated 0 after internal queue was finished
- fix: double `play` calls making `Player` paused

## 0.0.3+3

- docs: document updated `media_kit_video`, `media_kit_libs_macos_video` and `media_kit_libs_ios_video`

## 0.0.3+2

- docs: document updated `media_kit_video`

## 0.0.3+1

- docs: document updated `media_kit_native_event_loop`

## 0.0.3

- fix: unable to publish iOS to AppStore
- fix: support for iOS simulator

## 0.0.2

- macOS support
- iOS support
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

## 0.0.1

- Microsoft Windows support
- GNU/Linux support
- Initial release
