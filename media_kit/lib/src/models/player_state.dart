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
  Playlist playlist = Playlist([]);

  /// Whether [Player] is playing or not.
  bool isPlaying = false;

  /// Whether currently playing [Media] in [Player] has ended or not.
  bool isCompleted = false;

  /// Current playback position of the [Player].
  Duration position = Duration.zero;

  /// Duration of the currently playing [Media] in the [Player].
  Duration duration = Duration.zero;

  /// Current volume of the [Player].
  double volume = 1.0;

  /// Current playback rate of the [Player].
  double rate = 1.0;

  /// Current pitch of the [Player].
  double pitch = 1.0;

  /// Whether the [Player] is buffering.
  bool isBuffering = false;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  AudioParams audioParams = AudioParams();

  /// Audio bitrate of the currently playing [Media].
  double? audioBitrate;
}
