/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/player_log.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/player_error.dart';

/// Private class for event handling of [Player].
class PlayerStreams {
  /// [List] of currently opened [Media]s.
  final Stream<Playlist> playlist;

  /// Whether [Player] is playing or not.
  final Stream<bool> playing;

  /// Whether currently playing [Media] in [Player] has ended or not.
  final Stream<bool> completed;

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
  final Stream<bool> buffering;

  /// [Stream] emitting [PlayerLog]s.
  final Stream<PlayerLog> log;

  /// [Stream] raising [PlayerError]s.
  /// This may be used to catch errors raised by [Player].
  final Stream<PlayerError> error;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  final Stream<AudioParams> audioParams;

  /// Audio bitrate of the currently playing [Media] in the [Player].
  final Stream<double?> audioBitrate;

  /// Currently selected [AudioDevice].
  final Stream<AudioDevice> audioDevice;

  /// Currently available [AudioDevice]s.
  final Stream<List<AudioDevice>> audioDevices;

  /// Currently selected video, audio and subtitle tracks.
  final Stream<Track> track;

  /// Currently available video, audio and subtitle tracks.
  final Stream<Tracks> tracks;

  const PlayerStreams(
    this.playlist,
    this.playing,
    this.completed,
    this.position,
    this.duration,
    this.volume,
    this.rate,
    this.pitch,
    this.buffering,
    this.log,
    this.error,
    this.audioParams,
    this.audioBitrate,
    this.audioDevice,
    this.audioDevices,
    this.track,
    this.tracks,
  );
}
