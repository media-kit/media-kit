/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;

import 'package:media_kit/src/platform_player.dart';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

/// {@template web_player}
///
/// Player
/// ------
///
/// HTML [html.VideoElement] based implementation of [PlatformPlayer].
///
/// {@endtemplate}
class Player extends PlatformPlayer {
  /// {@macro web_player}
  Player({required super.configuration})
      : _handle = js.context[_kInstanceCount] ?? 0,
        _element = html.VideoElement() {
    _element
      ..autoplay = false
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..setAttribute('autoplay', 'false')
      ..setAttribute('playsinline', 'true')
      ..pause();
    // Initialize or increment the instance count.
    js.context[_kInstanceCount] ??= 0;
    js.context[_kInstanceCount]++;
    // Store the [html.VideoElement] instance in global [js.context].
    js.context[_kInstances] ??= js.JsObject.jsify({});
    js.context[_kInstances][_handle] = _element;
  }

  @override
  FutureOr<void> dispose({int code = 0}) async {
    _element
      ..src = ''
      ..load()
      ..remove();
    // Remove the [html.VideoElement] instance from global [js.context].
    js.context[_kInstances].deleteProperty(_handle);
    await super.dispose();
  }

  @override
  FutureOr<void> open(
    Playable playable, {
    bool play = true,
    bool evictExtrasCache = true,
  }) {
    if (playable is Media) {
      _element.src = playable.uri;
    }
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> play() async {
    await _element.play();
  }

  @override
  FutureOr<void> pause() {
    _element.pause();
  }

  @override
  FutureOr<void> playOrPause() async {
    if (_element.paused) {
      await _element.play();
    } else {
      _element.pause();
    }
  }

  @override
  FutureOr<void> add(Media media) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> remove(int index) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> next() {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> previous() {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> jump(int index) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> move(int from, int to) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> seek(Duration duration) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setPlaylistMode(PlaylistMode playlistMode) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setVolume(double volume) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setRate(double rate) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setPitch(double pitch) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setShuffle(bool shuffle) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setAudioDevice(AudioDevice audioDevice) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setVideoTrack(VideoTrack track) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setAudioTrack(AudioTrack track) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  FutureOr<void> setSubtitleTrack(SubtitleTrack track) {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<int> get handle => Future.value(_handle);

  /// Unique handle of this [Player] instance.
  final int _handle;

  /// HTML [html.VideoElement] instance reference.
  final html.VideoElement _element;

  /// JavaScript object attribute used to store various [VideoElement] instances in [js.context].
  static const _kInstances = '\$com.alexmercerind.media_kit.instances';

  /// JavaScript object attribute used to store the instance count of [Player] in [js.context].
  static const _kInstanceCount = '\$com.alexmercerind.media_kit.instance_count';
}
