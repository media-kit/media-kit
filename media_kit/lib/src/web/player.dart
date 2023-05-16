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
  Future<void> dispose() async {
    _element
      ..src = ''
      ..load()
      ..remove();
    // Remove the [html.VideoElement] instance from global [js.context].
    js.context[_kInstances].deleteProperty(_handle);
    await super.dispose();
  }

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool evictExtrasCache = true,
  }) async {
    if (playable is Media) {
      _element.src = playable.uri;
    }
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> play() async {
    await _element.play();
  }

  @override
  Future<void> pause() async {
    _element.pause();
  }

  @override
  Future<void> playOrPause() async {
    if (_element.paused) {
      await _element.play();
    } else {
      _element.pause();
    }
  }

  @override
  Future<void> add(Media media) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> remove(int index) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> next() async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> previous() async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> jump(int index) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> move(int from, int to) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> seek(Duration duration) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setVolume(double volume) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setRate(double rate) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setPitch(double pitch) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setShuffle(bool shuffle) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setAudioDevice(AudioDevice audioDevice) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setVideoTrack(VideoTrack track) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setAudioTrack(AudioTrack track) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    // TODO(@alexmercerind): Missing implementation.
  }

  @override
  Future<int> get handle => Future.value(_handle);

  /// Unique handle of this [Player] instance.
  final int _handle;

  /// [html.VideoElement] instance reference.
  final html.VideoElement _element;

  /// JavaScript object attribute used to store various [VideoElement] instances in [js.context].
  static const _kInstances = '\$com.alexmercerind.media_kit.instances';

  /// JavaScript object attribute used to store the instance count of [Player] in [js.context].
  static const _kInstanceCount = '\$com.alexmercerind.media_kit.instance_count';
}
