/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/audio_params.dart';

/// Current [Player] state.
class PlayerState {
  /// [List] of currently opened [Media]s.
  final Playlist playlist;

  /// Whether [Player] is playing or not.
  final bool isPlaying;

  /// Whether currently playing [Media] in [Player] has ended or not.
  final bool isCompleted;

  /// Current playback position of the [Player].
  final Duration position;

  /// Duration of the currently playing [Media] in the [Player].
  final Duration duration;

  /// Current volume of the [Player].
  final double volume;

  /// Current playback rate of the [Player].
  final double rate;

  /// Current pitch of the [Player].
  final double pitch;

  /// Whether the [Player] is buffering.
  final bool isBuffering;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  final AudioParams audioParams;

  /// Audio bitrate of the currently playing [Media].
  final double? audioBitrate;

  PlayerState({
    this.playlist = const Playlist([]),
    this.isPlaying = false,
    this.isCompleted = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.isBuffering = false,
    this.audioParams = const AudioParams(),
    this.audioBitrate,
  });

  PlayerState copyWith({
    Playlist? playlist,
    bool? isPlaying,
    bool? isCompleted,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? isBuffering,
    AudioParams? audioParams,
    double? audioBitrate,
  }) {
    return PlayerState(
      playlist: playlist ?? this.playlist,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      isBuffering: isBuffering ?? this.isBuffering,
      audioParams: audioParams ?? this.audioParams,
      audioBitrate: audioBitrate ?? this.audioBitrate,
    );
  }
}
