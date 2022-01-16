/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/models/media.dart';
import 'package:libmpv/src/dynamic_library.dart';
import 'package:libmpv/src/core/initializer.dart';

import 'package:libmpv/generated/bindings.dart' as generated;

typedef Playlist = List<Media>;

/// ## Player
///
/// [Player] class provides high-level interface for media playback.
///
/// ```dart
/// final player = Player();
/// player.open(
///   [
///     Media('https://alexmercerind.github.io/music.mp3'),
///     Media('file://C:/documents/video.mp4'),
///   ],
/// );
/// player.play();
/// ```
///
class Player {
  /// ## Player
  ///
  /// [Player] class provides high-level interface for media playback.
  ///
  /// ```dart
  /// final player = Player();
  /// player.open(
  ///   [
  ///     Media('https://alexmercerind.github.io/music.mp3'),
  ///     Media('file://C:/documents/video.mp4'),
  ///   ],
  /// );
  /// player.play();
  /// ```
  ///
  Player({
    bool video = true,
    bool osc = true,
    void Function()? onCreate,
  }) {
    _video = video;
    _osc = osc;
    _create().then(
      (_) => onCreate?.call(),
    );
  }

  /// Current state of the [Player]. For listening to these values and events, use [Player.streams] instead.
  _PlayerState state = _PlayerState();

  /// Various event streams to listen to events of a [Player].
  ///
  /// ```dart
  /// final player = Player();
  /// player.position.listen((position) {
  ///   print(position.inMilliseconds);
  /// });
  /// ```
  ///
  /// There are a lot of events like [isPlaying], [medias], [index] etc. to listen to & cause UI re-build.
  ///
  late _PlayerStreams streams;

  /// MPV handle of the internal instance.
  Pointer<generated.mpv_handle> get handle => _handle;

  /// Disposes the [Player] instance & releases the resources.
  Future<void> dispose({int code = 0}) async {
    await _completer.future;
    _command(
      [
        'quit',
        code.toString(),
      ],
    );
    _playlistController.close();
    _isPlayingController.close();
    _isCompletedController.close();
    _positionController.close();
    _durationController.close();
    _indexController.close();
    mpv.mpv_terminate_destroy(_handle);
  }

  /// Opens a [List] of [Media]s into the [Player] as a playlist.
  /// Previously opened, added or inserted [Media]s get removed.
  ///
  /// ```dart
  /// player.open(
  ///   [
  ///     Media('https://alexmercerind.github.io/music.mp3'),
  ///     Media('file://C:/documents/video.mp4'),
  ///   ],
  /// );
  /// ```
  Future<void> open(Playlist playlist) async {
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
    for (int i = 0; i < playlist.length; i++) {
      _command(
        [
          'loadfile',
          playlist[i].uri,
          i == 0 ? 'replace' : 'append',
        ],
      );
    }
    state.playlist = playlist;
    _playlistController.add(state.playlist);
  }

  /// Starts playing the [Player].
  Future<void> play() async {
    await _completer.future;
    var name = 'pause'.toNativeUtf8();
    var flag = calloc<Int8>();
    flag.value = 0;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
  }

  /// Pauses the [Player].
  Future<void> pause() async {
    await _completer.future;
    var name = 'pause'.toNativeUtf8();
    var flag = calloc<Int8>();
    flag.value = 1;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
  }

  /// Appends a [Media] to the [Player]'s playlist.
  Future<void> add(Media media) async {
    await _completer.future;
    _command(
      [
        'loadfile',
        media.uri,
        'append',
        null,
      ],
    );
    state.playlist.add(media);
    _playlistController.add(state.playlist);
  }

  /// Removes the [Media] at specified index from the [Player]'s playlist.
  Future<void> remove(int index) async {
    await _completer.future;
    _command(
      [
        'playlist-remove',
        index.toString(),
      ],
    );
    state.playlist.removeAt(index);
    _playlistController.add(state.playlist);
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  Future<void> next() async {
    await _completer.future;
    _command(
      [
        'playlist-next',
      ],
    );
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  Future<void> back() async {
    await _completer.future;
    _command(
      [
        'playlist-prev',
      ],
    );
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  Future<void> jump(int index) async {
    await _completer.future;
    _command(
      [
        'playlist-play-index',
        index.toString(),
      ],
    );
  }

  /// Moves the playlist [Media] at [from], so that it takes the place of the [Media] [to].
  Future<void> move(int from, int to) async {
    await _completer.future;
    _command(
      [
        'playlist-move',
        from.toString(),
        to.toString(),
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
        null,
      ],
    );
  }

  /// Sets the playback volume of the [Player]. Defaults to `100.0`.
  set volume(double volume) {
    () async {
      await _completer.future;
      var name = 'volume'.toNativeUtf8();
      var value = calloc<Double>();
      value.value = volume;
      mpv.mpv_set_property(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_DOUBLE,
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }();
  }

  /// Sets the playback rate of the [Player]. Defaults to `1.0`.
  set rate(double rate) {
    () async {
      await _completer.future;
      var name = 'speed'.toNativeUtf8();
      var value = calloc<Double>();
      value.value = rate;
      mpv.mpv_set_property(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_DOUBLE,
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }();
  }

  /// Enables or disables shuffle for [Player]. Default is `false`.
  set shuffle(bool shuffle) {
    () async {
      await _completer.future;
      _command(
        [
          shuffle ? 'playlist-shuffle' : 'playlist-unshuffle',
        ],
      );
    }();
  }

  Future<void> _create() async {
    streams = _PlayerStreams(
      [
        _playlistController,
        _isPlayingController,
        _isCompletedController,
        _positionController,
        _durationController,
        _indexController,
        _volumeController,
        _rateController,
        _isBufferingController,
      ],
    );
    _handle = await create(
      libmpvDynamicLibrary,
      (event) async {
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
          state.isCompleted = false;
          if (!_isCompletedController.isClosed) {
            _isCompletedController.add(false);
          }
        }
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
          state.isCompleted = true;
          if (!_isCompletedController.isClosed) {
            _isCompletedController.add(true);
          }
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          var prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            var isPlaying = prop.ref.data.cast<Int8>().value != 1;
            state.isPlaying = isPlaying;
            if (!_isPlayingController.isClosed) {
              _isPlayingController.add(isPlaying);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'paused-for-cache' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            var isBuffering = prop.ref.data.cast<Int8>().value != 0;
            state.isBuffering = isBuffering;
            if (!_isBufferingController.isClosed) {
              _isBufferingController.add(isBuffering);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'time-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var position = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.position = position;
            if (!_positionController.isClosed) {
              _positionController.add(position);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'duration' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var duration = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.duration = duration;
            if (!_durationController.isClosed) {
              _durationController.add(duration);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
            var index = prop.ref.data.cast<Int64>().value;
            state.index = index;
            if (!_indexController.isClosed) {
              _indexController.add(index);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'volume' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var volume = prop.ref.data.cast<Double>().value;
            state.volume = volume;
            if (!_volumeController.isClosed) {
              _volumeController.add(volume);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'speed' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            var rate = prop.ref.data.cast<Double>().value;
            state.rate = rate;
            if (!_rateController.isClosed) {
              _rateController.add(rate);
            }
          }
        }
      },
    );
    var properties = <String, int>{
      'pause': generated.mpv_format.MPV_FORMAT_FLAG,
      'time-pos': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'playlist-pos': generated.mpv_format.MPV_FORMAT_INT64,
      'seekable': generated.mpv_format.MPV_FORMAT_FLAG,
      'volume': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'speed': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'paused-for-cache': generated.mpv_format.MPV_FORMAT_FLAG,
    };
    properties.forEach((property, format) {
      var ptr = property.toNativeUtf8();
      mpv.mpv_observe_property(
        _handle,
        0,
        ptr.cast(),
        format,
      );
      calloc.free(ptr);
    });
    if (!_video) {
      var name = 'vo'.toNativeUtf8();
      var value = 'null'.toNativeUtf8();
      mpv.mpv_set_option_string(
        _handle,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    if (_osc) {
      var name = 'osc'.toNativeUtf8();
      Pointer<Int8> flag = calloc<Int8>()..value = 1;
      mpv.mpv_set_option(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        flag.cast(),
      );
      calloc.free(name);
      calloc.free(flag);
    }
    _completer.complete();
  }

  /// Calls MPV command passed as [args]. Automatically freeds memory after command sending.
  void _command(List<String?> args) {
    final ptr = args
        .map((String? string) =>
            string == null ? nullptr : string.toNativeUtf8())
        .toList()
        .cast<Pointer<Utf8>>();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join('').length);
    for (int index = 0; index < args.length; index++) {
      arr[index] = ptr[index];
    }
    mpv.mpv_command(
      _handle,
      arr.cast(),
    );
    for (int i = 0; i < args.length; i++) {
      if (args[i] != null) {
        calloc.free(ptr[i]);
      }
    }
    calloc.free(arr);
  }

  /// Whether video is visible or not.
  late bool _video;

  /// Whether on screen controls are visible or not.
  late bool _osc;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  final Completer<void> _completer = Completer();

  /// Internally used [StreamController].
  final StreamController<List<Media>> _playlistController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> _isPlayingController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> _isCompletedController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<Duration> _positionController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<Duration> _durationController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<int> _indexController = StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<double> _volumeController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<double> _rateController = StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> _isBufferingController =
      StreamController.broadcast();
}

/// Private class to keep state of the [Player].
class _PlayerState {
  /// [List] of currently opened [Media]s.
  Playlist playlist = [];

  /// If the [Player] is playing.
  bool isPlaying = false;

  /// If the [Player]'s playback is completed.
  bool isCompleted = false;

  /// Current playback position of the [Player].
  Duration position = Duration.zero;

  /// Duration of the currently playing [Media] in the [Player].
  Duration duration = Duration.zero;

  /// Index of the currently playing [Media] in the playlist.
  int index = 0;

  /// Current volume of the [Player].
  double volume = 1.0;

  /// Current playback rate of the [Player].
  double rate = 1.0;

  /// Whether the [Player] has stopped for buffering.
  bool isBuffering = false;
}

/// Private class for event handling of [Player].
class _PlayerStreams {
  /// [List] of currently opened [Media]s.
  late Stream<Playlist> playlist;

  /// If the [Player] is playing.
  late Stream<bool> isPlaying;

  /// If the [Player]'s playback is completed.
  late Stream<bool> isCompleted;

  /// Current playback position of the [Player].
  late Stream<Duration> position;

  /// Duration of the currently playing [Media] in the [Player].
  late Stream<Duration> duration;

  /// Index of the currently playing [Media] in the playlist.
  late Stream<int> index;

  /// Current volume of the [Player].
  late Stream<double> volume;

  /// Current playback rate of the [Player].
  late Stream<double> rate;

  /// Whether the [Player] has stopped for buffering.
  late Stream<bool> isBuffering;

  _PlayerStreams(List<StreamController> controllers) {
    playlist = controllers[0].stream.cast();
    isPlaying = controllers[1].stream.cast();
    isCompleted = controllers[2].stream.cast();
    position = controllers[3].stream.cast();
    duration = controllers[4].stream.cast();
    index = controllers[5].stream.cast();
    volume = controllers[6].stream.cast();
    rate = controllers[7].stream.cast();
    isBuffering = controllers[8].stream.cast();
  }
}
