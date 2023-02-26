/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/player_error.dart';
import 'package:media_kit/src/models/player_state.dart';
import 'package:media_kit/src/models/playlist_mode.dart';
import 'package:media_kit/src/models/player_streams.dart';

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

  /// Enables on-screen libmpv controls.
  ///
  /// Default: `false`.
  final bool osc;

  /// Enables or disables video output.
  /// Default: `null`.
  final bool? vid;

  /// Sets the video output driver.
  /// Default: `null`.
  final String? vo;

  /// Sets manually specified location to the libmpv shared library & overrides the default look-up behavior.
  ///
  /// Default: `null`.
  final String? libmpv;

  /// Sets the name of the underlying window & process. This is visible inside the Windows' volume mixer.
  ///
  /// Default: `null`.
  final String? title;

  /// Optional callback invoked when the internals of the [Player] are configured & ready for playback.
  ///
  /// Default: `null`.
  final void Function()? ready;

  /// {@macro player_configuration}
  const PlayerConfiguration({
    this.events = true,
    this.osc = false,
    this.vid,
    this.vo,
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
  late final PlayerState state = PlayerState();

  /// Current state of the player available as listenable [Stream]s.
  late final PlayerStreams streams = PlayerStreams(
    playlistController.stream,
    isPlayingController.stream,
    isCompletedController.stream,
    positionController.stream,
    durationController.stream,
    volumeController.stream,
    rateController.stream,
    pitchController.stream,
    isBufferingController.stream,
    errorController.stream,
    audioParamsController.stream,
    audioBitrateController.stream,
  );

  @mustCallSuper
  FutureOr<void> dispose({int code = 0}) async {
    await playlistController.close();
    await isPlayingController.close();
    await isCompletedController.close();
    await positionController.close();
    await durationController.close();
    await volumeController.close();
    await rateController.close();
    await pitchController.close();
    await isBufferingController.close();
    await errorController.close();
    await audioParamsController.close();
    await audioBitrateController.close();
  }

  FutureOr<void> open(
    Playlist playlist, {
    bool play = true,
    bool evictCache = true,
  }) {}

  FutureOr<void> play() {}

  FutureOr<void> pause() {}

  FutureOr<void> playOrPause() {}

  FutureOr<void> add(Media media) {}

  FutureOr<void> remove(int index) {}

  FutureOr<void> next() {}

  FutureOr<void> previous() {}

  FutureOr<void> jump(int index, {bool open = false}) {}

  FutureOr<void> move(int from, int to) {}

  FutureOr<void> seek(Duration duration) {}

  FutureOr<void> setPlaylistMode(PlaylistMode playlistMode) {}

  set volume(double value) {}

  set rate(double value) {}

  set pitch(double value) {}

  set shuffle(bool value) {}

  set audioDevice(FutureOr<AudioDevice> device) {}

  FutureOr<AudioDevice> get audioDevice {
    throw UnimplementedError(
      '[PlatformPlayer.audioDevice] is not implemented.',
    );
  }

  Future<List<AudioDevice>> get availableAudioDevices async {
    throw UnimplementedError(
      '[PlatformPlayer.availableAudioDevices] is not implemented.',
    );
  }

  Future<int> get handle {
    throw UnimplementedError(
      '[PlatformPlayer.handle] is not implemented.',
    );
  }

  @protected
  final StreamController<Playlist> playlistController =
      StreamController.broadcast();

  @protected
  final StreamController<bool> isPlayingController =
      StreamController.broadcast();

  @protected
  final StreamController<bool> isCompletedController =
      StreamController.broadcast();

  @protected
  final StreamController<Duration> positionController =
      StreamController.broadcast();

  @protected
  final StreamController<Duration> durationController =
      StreamController.broadcast();

  @protected
  final StreamController<double> volumeController =
      StreamController.broadcast();

  @protected
  final StreamController<double> rateController = StreamController.broadcast();

  @protected
  final StreamController<double> pitchController = StreamController.broadcast();

  @protected
  final StreamController<bool> isBufferingController =
      StreamController.broadcast();

  @protected
  final StreamController<PlayerError> errorController =
      StreamController.broadcast();

  @protected
  final StreamController<AudioParams> audioParamsController =
      StreamController.broadcast();

  @protected
  final StreamController<double?> audioBitrateController =
      StreamController.broadcast();
}
