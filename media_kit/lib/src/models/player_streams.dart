/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/player_error.dart';
import 'package:media_kit/src/models/player_log.dart';

/// Private class for event handling of [Player].
class PlayerStreams {
  /// [List] of currently opened [Media]s.
  final Stream<Playlist> playlist;

  /// Whether [Player] is playing or not.
  final Stream<bool> isPlaying;

  /// Whether currently playing [Media] in [Player] has ended or not.
  final Stream<bool> isCompleted;

  /// Current playback position of the [Player].
  final Stream<Duration> position;

  /// Duration of the currently playing [Media] in the [Player].
  final Stream<Duration> duration;

  /// Current volume of the [Player].
  final Stream<double> volume;

  /// Current playback rate of the [Player].
  final Stream<double> rate;

  /// Current pitch of the [Player].
  final Stream<double> pitch;

  /// Whether the [Player] has stopped for buffering.
  final Stream<bool> isBuffering;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  final Stream<AudioParams> audioParams;

  /// Audio bitrate of the currently playing [Media] in the [Player].
  final Stream<double?> audioBitrate;

  /// [Stream] emitting [PlayerLog]s.
  final Stream<PlayerLog> log;

  /// [Stream] raising [PlayerError]s.
  /// This may be used to catch errors raised by [Player].
  final Stream<PlayerError> error;

  const PlayerStreams(
    this.playlist,
    this.isPlaying,
    this.isCompleted,
    this.position,
    this.duration,
    this.volume,
    this.rate,
    this.pitch,
    this.isBuffering,
    this.log,
    this.error,
    this.audioParams,
    this.audioBitrate,
  );
}
