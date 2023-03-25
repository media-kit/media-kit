/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';

/// Current [Player] state.
class PlayerState {
  /// [List] of currently opened [Media]s.
  final Playlist playlist;

  /// Whether [Player] is playing or not.
  final bool playing;

  /// Whether currently playing [Media] in [Player] has ended or not.
  final bool completed;

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
  final bool buffering;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  final AudioParams audioParams;

  /// Audio bitrate of the currently playing [Media].
  final double? audioBitrate;

  /// Currently selected [AudioDevice].
  final AudioDevice audioDevice;

  /// Currently available [AudioDevice]s.
  final List<AudioDevice> audioDevices;

  /// Currently selected video, audio & subtitle tracks.
  final Track track;

  /// Currently available video, audio & subtitle tracks.
  final Tracks tracks;

  const PlayerState({
    this.playlist = const Playlist([]),
    this.playing = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.buffering = false,
    this.audioParams = const AudioParams(),
    this.audioBitrate,
    this.audioDevice = const AudioDevice('auto', ''),
    this.audioDevices = const [AudioDevice('auto', '')],
    this.track = const Track(),
    this.tracks = const Tracks(),
  });

  PlayerState copyWith({
    Playlist? playlist,
    bool? playing,
    bool? completed,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? buffering,
    AudioParams? audioParams,
    double? audioBitrate,
    AudioDevice? audioDevice,
    List<AudioDevice>? audioDevices,
    Track? track,
    Tracks? tracks,
  }) {
    return PlayerState(
      playlist: playlist ?? this.playlist,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      buffering: buffering ?? this.buffering,
      audioParams: audioParams ?? this.audioParams,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioDevice: audioDevice ?? this.audioDevice,
      audioDevices: audioDevices ?? this.audioDevices,
      track: track ?? this.track,
      tracks: tracks ?? this.tracks,
    );
  }

  @override
  String toString() => 'Player('
      'playlist: $playlist, '
      'playing: $playing, '
      'completed: $completed, '
      'position: $position, '
      'duration: $duration, '
      'volume: $volume, '
      'rate: $rate, '
      'pitch: $pitch, '
      'buffering: $buffering, '
      'audioParams: $audioParams, '
      'audioBitrate: $audioBitrate, '
      'audioDevice: $audioDevice, '
      'audioDevices: $audioDevices, '
      'track: $track, '
      'tracks: $tracks, ';
}
