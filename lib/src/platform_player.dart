/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/playlist.dart';
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
  /// For showing video output inside the Flutter Widget tree.
  /// Setting this as `false` will cause video output to be displayed in a separate window.
  /// For this to work, [vo] must be non-`null`.
  /// Default: `true`.
  final bool texture;

  /// Enables on-screen libmpv controls.
  /// For this to work, [vo] must be non-`null` & [texture] must be `null`.
  /// Default: `false`.
  final bool osc;

  /// For enabling video rendering.
  /// If you intend to play only audio, set this to a `'null'` [String] to improve performance.
  /// Default: `true`.
  final String? vo;

  /// Sets manually specified location to the libmpv shared library & overrides the default look-up behavior.
  /// Default: `null`.
  final String? libmpv;

  /// Sets the `HWND` title of the process.
  /// This is visible inside the Windows' volume mixer.
  /// Default: `null`.
  final String? title;

  /// Optional callback invoked when the internals of the [Player] are configured & ready for playback.
  final void Function()? ready;

  /// {@macro player_configuration}
  const PlayerConfiguration({
    this.texture = true,
    this.osc = false,
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
  Future<void> dispose({int code = 0}) async {
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

  Future<void> open(
    Playlist playlist, {
    bool play = true,
    bool evictCache = true,
  }) async {}

  Future<void> play() async {}

  Future<void> pause() async {}

  Future<void> playOrPause() async {}

  Future<void> add(Media media) async {}

  Future<void> remove(int index) async {}

  Future<void> next() async {}

  Future<void> previous() async {}

  Future<void> jump(int index, {bool open = false}) async {}

  Future<void> move(int from, int to) async {}

  Future<void> seek(Duration duration) async {}

  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {}

  set volume(double value) {}

  set rate(double value) {}

  set pitch(double value) {}

  set shuffle(bool value) {}

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
