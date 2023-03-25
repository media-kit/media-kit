/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/player_log.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/player_error.dart';
import 'package:media_kit/src/models/player_state.dart';
import 'package:media_kit/src/models/playlist_mode.dart';
import 'package:media_kit/src/models/player_streams.dart';

/// {@template mpv_log_level}
///
/// MPVLogLevel
/// --------------------
/// Options to customise the [Player] libmpv backend log level.
///
/// {@endtemplate}
enum MPVLogLevel {
  /// Disable absolutely all messages.
  none,

  /// Critical/aborting errors.
  fatal,

  /// Simple errors.
  error,

  /// Possible problems.
  warn,

  /// Informational message.
  info,

  /// Noisy informational message.
  v,

  /// Very noisy technical information.
  debug,

  /// Extremely noisy.
  trace,
}

/// {@template player_configuration}
///
/// PlayerConfiguration
/// --------------------
/// Configurable options for customizing the [Player] behavior.
///
/// {@endtemplate}
class PlayerConfiguration {
  /// Enables or disables event handling. This may improve performance if there is no need to listen to events.
  /// Default: `true`.
  final bool events;

  /// Sets the log level on libmpv backend.
  /// Default: `none`.
  final MPVLogLevel logLevel;

  /// Enables on-screen controls on libmpv backend.
  /// Default: `false`.
  final bool osc;

  /// Enables or disables video output on libmpv backend.
  /// Default: `null`.
  final bool? vid;

  /// Sets the video output driver on libmpv backend.
  /// Default: `null`.
  final String? vo;

  /// Enables or disables pitch shift control on libmpv backend.
  ///
  /// Enabling this option may result in de-syncing of audio & video.
  /// Thus, usage in audio only applications is recommended.
  /// This uses `scaletempo` under the hood & disables `audio-pitch-correction`.
  ///
  /// See: https://github.com/alexmercerind/media_kit/issues/45
  ///
  /// Default: `false`.
  final bool pitch;

  /// Sets manually specified location to the libmpv shared library & overrides the default look-up behavior.
  ///
  /// Default: `null`.
  final String? libmpv;

  /// Sets the name of the underlying window & process on libmpv backend. This is visible inside the Windows' volume mixer.
  ///
  /// Default: `null`.
  final String? title;

  /// Optional callback invoked when the internals of the [Player] are initialized & ready for playback.
  ///
  /// Default: `null`.
  final void Function()? ready;

  /// {@macro player_configuration}
  const PlayerConfiguration({
    this.events = true,
    this.logLevel = MPVLogLevel.none,
    this.osc = false,
    this.vid,
    this.vo,
    this.pitch = false,
    this.libmpv,
    this.title,
    this.ready,
  });
}

/// {@template platform_player}
/// PlatformPlayer
/// --------------
///
/// This class provides the interface for platform specific player implementations.
/// The platform specific implementations are expected to implement the methods accordingly.
///
/// The subclasses are then used in composition with the [Player] class, based on the platform the application is running on.
///
/// {@endtemplate}
abstract class PlatformPlayer {
  /// {@macro platform_player}
  PlatformPlayer({required this.configuration});

  /// User defined configuration for [Player].
  final PlayerConfiguration configuration;

  /// Current state of the player.
  late PlayerState state = PlayerState();

  /// Current state of the player available as listenable [Stream]s.
  late PlayerStreams streams = PlayerStreams(
    playlistController.stream,
    playingController.stream,
    completedController.stream,
    positionController.stream,
    durationController.stream,
    volumeController.stream,
    rateController.stream,
    pitchController.stream,
    bufferingController.stream,
    logController.stream,
    errorController.stream,
    audioParamsController.stream,
    audioBitrateController.stream,
    audioDeviceController.stream,
    audioDevicesController.stream,
    trackController.stream,
    tracksController.stream,
  );

  @mustCallSuper
  FutureOr<void> dispose({int code = 0}) => Future.wait(
        [
          playlistController.close(),
          playingController.close(),
          completedController.close(),
          positionController.close(),
          durationController.close(),
          volumeController.close(),
          rateController.close(),
          pitchController.close(),
          bufferingController.close(),
          logController.close(),
          errorController.close(),
          audioParamsController.close(),
          audioBitrateController.close(),
          audioDeviceController.close(),
          audioDevicesController.close(),
          trackController.close(),
          tracksController.close(),
        ],
      );

  FutureOr<void> open(
    Playlist playlist, {
    bool play = true,
    bool evictCache = true,
  }) {
    throw UnimplementedError(
      '[PlatformPlayer.open] is not implemented.',
    );
  }

  FutureOr<void> play() {
    throw UnimplementedError(
      '[PlatformPlayer.play] is not implemented.',
    );
  }

  FutureOr<void> pause() {
    throw UnimplementedError(
      '[PlatformPlayer.pause] is not implemented.',
    );
  }

  FutureOr<void> playOrPause() {
    throw UnimplementedError(
      '[PlatformPlayer.playOrPause] is not implemented.',
    );
  }

  FutureOr<void> add(Media media) {
    throw UnimplementedError(
      '[PlatformPlayer.add] is not implemented.',
    );
  }

  FutureOr<void> remove(int index) {
    throw UnimplementedError(
      '[PlatformPlayer.remove] is not implemented.',
    );
  }

  FutureOr<void> next() {
    throw UnimplementedError(
      '[PlatformPlayer.next] is not implemented.',
    );
  }

  FutureOr<void> previous() {
    throw UnimplementedError(
      '[PlatformPlayer.previous] is not implemented.',
    );
  }

  FutureOr<void> jump(int index, {bool open = false}) {
    throw UnimplementedError(
      '[PlatformPlayer.jump] is not implemented.',
    );
  }

  FutureOr<void> move(int from, int to) {
    throw UnimplementedError(
      '[PlatformPlayer.move] is not implemented.',
    );
  }

  FutureOr<void> seek(Duration duration) {
    throw UnimplementedError(
      '[PlatformPlayer.seek] is not implemented.',
    );
  }

  FutureOr<void> setPlaylistMode(PlaylistMode playlistMode) {
    throw UnimplementedError(
      '[PlatformPlayer.setPlaylistMode] is not implemented.',
    );
  }

  FutureOr<void> setVolume(double volume) {
    throw UnimplementedError(
      '[PlatformPlayer.volume] is not implemented.',
    );
  }

  FutureOr<void> setRate(double rate) {
    throw UnimplementedError(
      '[PlatformPlayer.rate] is not implemented.',
    );
  }

  FutureOr<void> setPitch(double pitch) {
    throw UnimplementedError(
      '[PlatformPlayer.pitch] is not implemented.',
    );
  }

  FutureOr<void> setShuffle(bool shuffle) {
    throw UnimplementedError(
      '[PlatformPlayer.shuffle] is not implemented.',
    );
  }

  FutureOr<void> setAudioDevice(AudioDevice audioDevice) {
    throw UnimplementedError(
      '[PlatformPlayer.setAudioDevice] is not implemented.',
    );
  }

  FutureOr<void> setVideoTrack(VideoTrack track) {
    throw UnimplementedError(
      '[PlatformPlayer.setVideoTrack] is not implemented.',
    );
  }

  FutureOr<void> setAudioTrack(AudioTrack track) {
    throw UnimplementedError(
      '[PlatformPlayer.setAudioTrack] is not implemented.',
    );
  }

  FutureOr<void> setSubtitleTrack(SubtitleTrack track) {
    throw UnimplementedError(
      '[PlatformPlayer.setSubtitleTrack] is not implemented.',
    );
  }

  Future<int> get handle {
    throw UnimplementedError(
      '[PlatformPlayer.handle] is not implemented.',
    );
  }

  @protected
  final StreamController<Playlist> playlistController =
      StreamController<Playlist>.broadcast();

  @protected
  final StreamController<bool> playingController =
      StreamController<bool>.broadcast();

  @protected
  final StreamController<bool> completedController =
      StreamController<bool>.broadcast();

  @protected
  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();

  @protected
  final StreamController<Duration> durationController =
      StreamController.broadcast();

  @protected
  final StreamController<double> volumeController =
      StreamController.broadcast();

  @protected
  final StreamController<double> rateController =
      StreamController<double>.broadcast();

  @protected
  final StreamController<double> pitchController =
      StreamController<double>.broadcast();

  @protected
  final StreamController<bool> bufferingController =
      StreamController<bool>.broadcast();

  @protected
  final StreamController<PlayerLog> logController =
      StreamController<PlayerLog>.broadcast();

  @protected
  final StreamController<PlayerError> errorController =
      StreamController<PlayerError>.broadcast();

  @protected
  final StreamController<AudioParams> audioParamsController =
      StreamController<AudioParams>.broadcast();

  @protected
  final StreamController<double?> audioBitrateController =
      StreamController<double?>.broadcast();

  @protected
  final StreamController<AudioDevice> audioDeviceController =
      StreamController<AudioDevice>.broadcast();

  @protected
  final StreamController<List<AudioDevice>> audioDevicesController =
      StreamController<List<AudioDevice>>.broadcast();

  @protected
  final StreamController<Track> trackController =
      StreamController<Track>.broadcast();

  @protected
  final StreamController<Tracks> tracksController =
      StreamController<Tracks>.broadcast();
}
