/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/models/media.dart';

import 'package:libmpv/src/core/initializer.dart' as core;
import 'package:libmpv/generated/bindings.dart' as generated;

/// Player
/// ------
/// A [Player] object can be used for media playback.
/// Takes libmpv's DLL or shared object path as argument.
///
/// ```dart
/// var player = Player('/usr/lib/libmpv.so');
/// player.open(
///   [
///   Media('https://www.example.com/music.mp3'),
///   Media('file://C:/documents/video.mp4'),
///   ],
/// );
/// player.play();
/// ```
///
class Player {
  Player(
    String path, {
    bool video = false,
  }) {
    _path = path;
    _video = video;
    _create();
  }

  /// Current state of the [Player]. For listening to these values and events, use [Player.streams] instead.
  _PlayerState state = _PlayerState();

  /// Various event streams to listen to events of a [Player].
  ///
  /// ```dart
  /// var player = Player(id: 0);
  /// player.streams.position..listen((position) {
  ///   print(position.inMilliseconds);
  /// });
  /// ```
  ///
  /// There are a lot of events like [isPlaying], [medias], [index] etc. to listen to & cause UI re-build.
  ///
  _PlayerStreams streams = _PlayerStreams();

  /// Disposes the [Player] instance & releases the resources.
  Future<void> dispose({int code = 0}) async {
    await _completer.future;
    _command(
      [
        'quit',
        code.toString(),
      ],
    );
  }

  /// Opens a [List] of [Media]s into the [Player] as a queue.
  /// Previously opened, added or inserted [Media]s get removed.
  ///
  /// ```dart
  /// player.open(
  ///   [
  ///     Media('https://www.example.com/music.mp3'),
  ///     Media('file://C:/documents/video.mp4'),
  ///   ],
  /// );
  /// ```
  Future<void> open(
    List<Media> medias, {
    bool play = false,
  }) async {
    await _completer.future;
    _command(
      [
        'playlist-play-index',
        'none',
      ],
    );
    _command(
      [
        'playlist-clear',
      ],
    );
    medias.asMap().forEach(
      (index, media) {
        if (index == 0 && play) {
          _command(
            [
              'loadfile',
              media.uri,
              'replace',
            ],
          );
        } else {
          _command(
            [
              'loadfile',
              media.uri,
              'append',
            ],
          );
        }
      },
    );
  }

  /// Starts playing the [Player].
  Future<void> play() async {
    await _completer.future;
    var flag = calloc<Int8>();
    flag.value = 0;
    core.mpv.mpv_set_property(
      _handle,
      'pause'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(flag);
  }

  /// Pauses the [Player].
  Future<void> pause() async {
    await _completer.future;
    var flag = calloc<Int8>();
    flag.value = 1;
    core.mpv.mpv_set_property(
      _handle,
      'pause'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(flag);
  }

  /// Appends a [Media] to the [Player]'s queue.
  Future<void> add(Media media) async {
    await _completer.future;
    _command(
      [
        'loadfile',
        media.uri,
        'append',
      ],
    );
  }

  /// Removes the [Media] at specified index from the [Player]'s queue.
  Future<void> remove(int index) async {
    await _completer.future;
    _command(
      [
        'playlist-remove',
        index.toString(),
      ],
    );
  }

  /// Jumps to next [Media] in the [Player]'s queue.
  Future<void> next() async {
    await _completer.future;
    _command(
      [
        'playlist-next',
      ],
    );
  }

  /// Jumps to previous [Media] in the [Player]'s queue.
  Future<void> back() async {
    await _completer.future;
    _command(
      [
        'playlist-prev',
      ],
    );
  }

  /// Jumps to specified [Media]'s index in the [Player]'s queue.
  Future<void> jump(int index) async {
    await _completer.future;
    _command(
      [
        'playlist-play-index',
        index.toString(),
      ],
    );
  }

  /// Seeks the currently playing [Media] in the [Player] by specified [Duration].
  Future<void> seek(Duration duration) async {
    await _completer.future;
    _command(
      [
        'seek',
        (duration.inMilliseconds / 1000).toStringAsFixed(4).toString(),
        'absolute',
      ],
    );
  }

  /// Sets the playback volume of the [Player]. Defaults to `1.0`.
  Future<void> setVolume(double volume) async {
    await _completer.future;
    var value = calloc<Double>();
    value.value = volume;
    core.mpv.mpv_set_property(
      _handle,
      'volume'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
      value.cast(),
    );
    calloc.free(value);
  }

  /// Sets the playback rate of the [Player]. Defaults to `1.0`.
  Future<void> setRate(double rate) async {
    await _completer.future;
    var value = calloc<Double>();
    value.value = rate;
    core.mpv.mpv_set_property(
      _handle,
      'speed'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
      value.cast(),
    );
    calloc.free(value);
  }

  Future<void> _create() async {
    _handle = await core.create(
      _path,
      (event) async {
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
          state.isCompleted = false;
          if (!streams.isCompletedController.isClosed) {
            streams.isCompletedController.add(false);
          }
        }
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
          state.isCompleted = true;
          if (!streams.isCompletedController.isClosed) {
            streams.isCompletedController.add(true);
          }
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          var prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            var isPlaying = prop.ref.data.cast<Int8>().value != 0;
            state.isPlaying = isPlaying;
            if (!streams.isPlayingController.isClosed) {
              streams.isPlayingController.add(isPlaying);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'time-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var position = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.position = position;
            if (!streams.positionController.isClosed) {
              streams.positionController.add(position);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'duration' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var duration = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.duration = duration;
            if (!streams.durationController.isClosed) {
              streams.durationController.add(duration);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
            var index = prop.ref.data.cast<Int64>().value;
            state.index = index;
            if (!streams.indexController.isClosed) {
              streams.indexController.add(index);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
            var playlist = <Media>[];
            var arr = prop.ref.data.cast<generated.mpv_node>().ref.u.list;
            for (int i = 0; i < arr.ref.num; i++) {
              var map = arr.ref.values[i].u.list;
              for (int j = 0; j < map.ref.num; j++) {
                var key = map.ref.keys[j].cast<Utf8>().toDartString();
                var value = map.ref.values[i];
                if (key == 'filename') {
                  var media = value.u.string.cast<Utf8>().toDartString();
                  playlist.add(medias[media]!);
                  continue;
                }
              }
            }
            state.playlist = playlist;
            if (!streams.playlistController.isClosed) {
              streams.playlistController.add(playlist);
            }
          }
        }
      },
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'pause'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'time-pos'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'duration'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'playlist'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_NODE,
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'playlist-pos'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_INT64,
    );
    core.mpv.mpv_observe_property(
      _handle,
      0,
      'seekable'.toNativeUtf8().cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
    );

    if (!_video) {
      core.mpv.mpv_set_option_string(
        _handle,
        'vo'.toNativeUtf8().cast(),
        'null'.toNativeUtf8().cast(),
      );
    }
    _completer.complete();
  }

  void _command(List<String> args) {
    final ptr = args
        .map((String string) => string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join('').length);
    for (int index = 0; index < args.length; index++) {
      arr[index] = ptr[index];
    }
    core.mpv.mpv_command(
      _handle,
      arr.cast(),
    );
    for (var element in ptr) {
      calloc.free(element);
    }
    calloc.free(arr);
  }

  /// Path to libmpv DLL or shared object.
  late String _path;

  /// Whether video is visible or not.
  late bool _video;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  final Completer<void> _completer = Completer();
}

/// Private class to keep state of the [Player].
class _PlayerState {
  /// [List] of currently opened [Media]s.
  List<Media> playlist = [];

  /// If the [Player] is playing.
  bool isPlaying = false;

  /// If the [Player] is buffering.
  bool isBuffering = false;

  /// If the [Player]'s playback is completed.
  bool isCompleted = false;

  /// Current playback position of the [Player].
  Duration position = Duration.zero;

  /// Duration of the currently playing [Media] in the [Player].
  Duration duration = Duration.zero;

  /// Index of the currently playing [Media] in the queue.
  int index = 0;

  /// Download progress of the currently playing [Media].
  double downloadProgress = 0.0;
}

/// Private class for event handling of [Player].
class _PlayerStreams {
  /// [List] of currently opened [Media]s.
  late Stream<List<Media>> playlist;

  /// If the [Player] is playing.
  late Stream<bool> isPlaying;

  /// If the [Player] is buffering.
  late Stream<bool> isBuffering;

  /// If the [Player]'s playback is completed.
  late Stream<bool> isCompleted;

  /// Current playback position of the [Player].
  late Stream<Duration> position;

  /// Duration of the currently playing [Media] in the [Player].
  late Stream<Duration> duration;

  /// Index of the currently playing [Media] in the queue.
  late Stream<int> index;

  /// Download progress of the currently playing [Media].
  late Stream<double> downloadProgress;

  /// Closes all the stream controllers.
  void dispose() {
    playlistController.close();
    isPlayingController.close();
    isBufferingController.close();
    isCompletedController.close();
    positionController.close();
    durationController.close();
    indexController.close();
    downloadProgressController.close();
  }

  _PlayerStreams() {
    playlist = playlistController.stream;
    isPlaying = isPlayingController.stream;
    isBuffering = isBufferingController.stream;
    isCompleted = isCompletedController.stream;
    position = positionController.stream;
    duration = durationController.stream;
    index = indexController.stream;
    downloadProgress = downloadProgressController.stream;
  }

  /// Internally used [StreamController].
  final StreamController<List<Media>> playlistController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> isPlayingController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> isBufferingController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> isCompletedController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<Duration> positionController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<Duration> durationController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<int> indexController = StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<double> downloadProgressController =
      StreamController.broadcast();
}
