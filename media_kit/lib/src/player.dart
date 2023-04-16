/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/player_state.dart';
import 'package:media_kit/src/models/playlist_mode.dart';
import 'package:media_kit/src/models/player_streams.dart';

import 'package:media_kit/src/utils.dart';
import 'package:media_kit/src/platform_player.dart';
import 'package:media_kit/src/libmpv/player.dart'
    if (dart.library.html) 'package:media_kit/src/platform_player.dart'
    as _libmpv show Player;
import 'package:media_kit/src/web/player.dart'
    if (dart.library.io) 'package:media_kit/src/platform_player.dart' as _web
    show Player;

/// {@template player}
///
/// Player
/// ------
///
/// [Player] class provides high-level abstraction for media playback.
/// Large number of features have been exposed as class methods & properties.
///
/// The instantaneous state may be accessed using the [state] getter & subscription to the them may be made using the [streams] available.
///
/// Call [dispose] to free the allocated resources back to the system.
///
/// ```dart
/// import 'package:media_kit/media_kit.dart';
///
/// MediaKit.ensureInitialized();
///
/// // Create a [Player] instance for audio or video playback.
///
/// final player = Player();
///
/// // Subscribe to event streams & listen to updates.
///
/// player.streams.playlist.listen((e) => print(e));
/// player.streams.playing.listen((e) => print(e));
/// player.streams.completed.listen((e) => print(e));
/// player.streams.position.listen((e) => print(e));
/// player.streams.duration.listen((e) => print(e));
/// player.streams.volume.listen((e) => print(e));
/// player.streams.rate.listen((e) => print(e));
/// player.streams.pitch.listen((e) => print(e));
/// player.streams.buffering.listen((e) => print(e));
/// player.streams.audioParams.listen((e) => print(e));
/// player.streams.audioBitrate.listen((e) => print(e));
/// player.streams.audioDevice.listen((e) => print(e));
/// player.streams.audioDevices.listen((e) => print(e));
///
///
/// // Open a playable [Media] or [Playlist].
///
/// await player.open(Media('file:///C:/Users/Hitesh/Music/Sample.mp3'));
/// await player.open(Media('file:///C:/Users/Hitesh/Video/Sample.mkv'));
/// await player.open(Media('asset:///videos/bee.mp4'));
/// await player.open(
///   Playlist(
///     [
///       Media('https://www.example.com/sample.mp4'),
///       Media('rtsp://www.example.com/live'),
///     ],
///     // Select the starting index.
///     index: 1,
///   ),
///   // Select whether playback should start or not.
///   play: false,
/// );
///
/// // Control playback state.
///
/// await player.play();
/// await player.pause();
/// await player.playOrPause();
/// await player.seek(const Duration(seconds: 10));
///
/// // Use or modify the queue.
///
/// await player.next();
/// await player.previous();
/// await player.jump(2);
/// await player.add(Media('https://www.example.com/sample.mp4'));
/// await player.move(0, 2);
///
/// // Customize speed, pitch, volume, shuffle, playlist mode, audio device.
///
/// await player.setRate(1.0);
/// await player.setPitch(1.2);
/// await player.setVolume(50.0);
/// await player.setShuffle(false);
/// await player.setPlaylistMode(PlaylistMode.loop);
/// await player.setAudioDevice(AudioDevice.auto());
///
/// // Release allocated resources back to the system.
///
/// await player.dispose();
/// ```
///
/// {@endtemplate}
///
class Player {
  /// {@macro player}
  Player({
    PlayerConfiguration configuration = const PlayerConfiguration(),
  }) {
    if (kIsWeb) {
      platform = _web.Player(configuration: configuration);
    } else if (Platform.isWindows) {
      platform = _libmpv.Player(configuration: configuration);
    } else if (Platform.isLinux) {
      platform = _libmpv.Player(configuration: configuration);
    } else if (Platform.isMacOS) {
      platform = _libmpv.Player(configuration: configuration);
    } else if (Platform.isIOS) {
      platform = _libmpv.Player(configuration: configuration);
    } else if (Platform.isAndroid) {
      platform = _libmpv.Player(configuration: configuration);
    }
  }

  /// Platform specific internal implementation initialized depending upon the current platform.
  PlatformPlayer? platform;

  /// Current state of the [Player].
  PlayerState get state => platform!.state;

  /// Current state of the [Player] available as listenable [Stream]s.
  PlayerStreams get streams => platform!.streams;

  /// Disposes the [Player] instance & releases the resources.
  FutureOr<void> dispose({int code = 0}) {
    return platform?.dispose();
  }

  /// Opens a [Media] or [Playlist] into the [Player].
  /// Passing [play] as `true` starts the playback immediately.
  ///
  /// ```dart
  /// await player.open(Media('asset:///assets/videos/sample.mp4'));
  /// await player.open(Media('file:///C:/Users/Hitesh/Music/Sample.mp3'));
  /// await player.open(
  ///   Playlist(
  ///     [
  ///       Media('file:///C:/Users/Hitesh/Music/Sample.mp3'),
  ///       Media('file:///C:/Users/Hitesh/Video/Sample.mkv'),
  ///       Media('https://www.example.com/sample.mp4'),
  ///       Media('rtsp://www.example.com/live'),
  ///     ],
  ///   ),
  ///   play: true,
  /// );
  /// ```
  ///
  FutureOr<void> open(
    Playable playable, {
    bool play = true,
    bool evictExtrasCache = true,
  }) {
    return platform?.open(
      playable,
      play: play,
      evictExtrasCache: evictExtrasCache,
    );
  }

  /// Starts playing the [Player].
  FutureOr<void> play() {
    return platform?.play();
  }

  /// Pauses the [Player].
  FutureOr<void> pause() {
    return platform?.pause();
  }

  /// Cycles between [play] & [pause] states of the [Player].
  FutureOr<void> playOrPause() {
    return platform?.playOrPause();
  }

  /// Appends a [Media] to the [Player]'s playlist.
  FutureOr<void> add(Media media) {
    return platform?.add(media);
  }

  /// Removes the [Media] at specified index from the [Player]'s playlist.
  FutureOr<void> remove(int index) {
    return platform?.remove(index);
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  FutureOr<void> next() {
    return platform?.next();
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  FutureOr<void> previous() {
    return platform?.previous();
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  FutureOr<void> jump(int index) {
    return platform?.jump(index);
  }

  /// Moves the playlist [Media] at [from], so that it takes the place of the [Media] [to].
  FutureOr<void> move(int from, int to) {
    return platform?.move(from, to);
  }

  /// Seeks the currently playing [Media] in the [Player] by specified [Duration].
  FutureOr<void> seek(Duration duration) {
    return platform?.seek(duration);
  }

  /// Sets playlist mode.
  FutureOr<void> setPlaylistMode(PlaylistMode playlistMode) {
    return platform?.setPlaylistMode(playlistMode);
  }

  /// Sets the playback volume of the [Player].
  /// Defaults to `100.0`.
  FutureOr<void> setVolume(double volume) {
    return platform?.setVolume(volume);
  }

  /// Sets the playback rate of the [Player].
  /// Defaults to `1.0`.
  FutureOr<void> setRate(double rate) {
    return platform?.setRate(rate);
  }

  /// Sets the relative pitch of the [Player].
  /// Defaults to `1.0`.
  FutureOr<void> setPitch(double pitch) {
    return platform?.setPitch(pitch);
  }

  /// Enables or disables shuffle for [Player].
  /// Default is `false`.
  FutureOr<void> setShuffle(bool shuffle) {
    return platform?.setShuffle(shuffle);
  }

  /// Sets the current [AudioDevice] for audio output.
  ///
  /// * Currently selected [AudioDevice] can be accessed using [state.audioDevice] or [streams.audioDevice].
  /// * The list of currently available [AudioDevice]s can be obtained accessed using [state.audioDevices] or [streams.audioDevices].
  FutureOr<void> setAudioDevice(AudioDevice audioDevice) {
    return platform?.setAudioDevice(audioDevice);
  }

  /// Sets the current [VideoTrack] for video output.
  ///
  /// * Currently selected [VideoTrack] can be accessed using [state.track.video] or [streams.track.video].
  /// * The list of currently available [VideoTrack]s can be obtained accessed using [state.tracks.video] or [streams.tracks.video].
  FutureOr<void> setVideoTrack(VideoTrack track) async {
    return platform?.setVideoTrack(track);
  }

  /// Sets the current [AudioTrack] for audio output.
  ///
  /// * Currently selected [AudioTrack] can be accessed using [state.track.audio] or [streams.track.audio].
  /// * The list of currently available [AudioTrack]s can be obtained accessed using [state.tracks.audio] or [streams.tracks.audio].
  FutureOr<void> setAudioTrack(AudioTrack track) async {
    return platform?.setAudioTrack(track);
  }

  /// Sets the current [SubtitleTrack] for subtitle output.
  ///
  /// * Currently selected [SubtitleTrack] can be accessed using [state.track.subtitle] or [streams.track.subtitle].
  /// * The list of currently available [SubtitleTrack]s can be obtained accessed using [state.tracks.subtitle] or [streams.tracks.subtitle].
  FutureOr<void> setSubtitleTrack(SubtitleTrack track) async {
    return platform?.setSubtitleTrack(track);
  }

  /// Internal platform specific identifier for this [Player] instance.
  ///
  /// Since, [int] is a primitive type, it can be used to pass this [Player] instance to native code without directly depending upon this library.
  ///
  Future<int> get handle {
    final result = platform?.handle;
    return result!;
  }
}
