/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'package:libmpv/src/dynamic_library.dart';
import 'package:libmpv/src/core/initializer.dart';
import 'package:libmpv/src/models/media.dart';
import 'package:libmpv/src/models/playlist.dart';
import 'package:libmpv/src/models/playlist_mode.dart';

import 'package:libmpv/generated/bindings.dart' as generated;

import 'package:libmpv/src/plugins/youtube.dart';

/// ## Player
///
/// [Player] class provides high-level interface for media playback.
///
/// ```dart
/// final player = Player();
/// player.open(
///   Playlist(
///     [
///       Media('https://alexmercerind.github.io/music.mp3'),
///       Media('file://C:/documents/video.mp4'),
///     ],
///   ),
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
  ///   Playlist(
  ///     [
  ///       Media('https://alexmercerind.github.io/music.mp3'),
  ///       Media('file://C:/documents/video.mp4'),
  ///     ],
  ///   ),
  /// );
  /// player.play();
  /// ```
  ///
  Player({
    this.video = true,
    this.osc = true,
    bool yt = true,
    this.crossfade = Duration.zero,
    this.title,
    void Function()? onCreate,
  }) {
    if (yt) {
      youtube = YouTube();
    }
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
    await _command(
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
    youtube?.close();
  }

  /// Opens a [List] of [Media]s into the [Player] as a playlist.
  /// Previously opened, added or inserted [Media]s get removed.
  ///
  /// ```dart
  /// player.open(
  ///   Playlist(
  ///     [
  ///       Media('https://alexmercerind.github.io/music.mp3'),
  ///       Media('file://C:/documents/video.mp4'),
  ///     ],
  ///   ),
  /// );
  /// ```
  Future<void> open(
    Playlist playlist, {
    bool play = true,
  }) async {
    // Clean-up existing cached [medias].
    medias.clear();
    // Restore current playlist.
    for (final media in playlist.medias) {
      medias[() {
        // Match with format retrieved by `mpv_get_property`.
        if (media.uri.startsWith('file')) {
          return Uri.parse(media.uri).toFilePath().replaceAll('\\', '/');
        } else {
          return media.uri;
        }
      }()] = media;
    }
    await _completer.future;
    final completer = Completer<void>();
    final receiver = ReceivePort()
      ..listen((value) {
        if (value == true) {
          completer.complete();
        }
      });
    final isolate = await Isolate.spawn(
      _mpvCommandLoadFileIsolate,
      [
        libmpv!,
        _handle.address,
        receiver.sendPort,
        ...playlist.medias.map((e) => e.uri),
      ],
    );
    await completer.future;
    isolate.kill();
    receiver.close();
    // Even though `replace` parameter in `loadfile` automatically causes the
    // [Media] to play but in certain cases like, where a [Media] is paused & then
    // new [Media] is [Player.open]ed it causes [Media] to not starting playing
    // automatically.
    // Thanks to <github.com/DomingoMG> for the fix!
    state.playlist = playlist;
    // To wait for the index change [jump] call.
    if (play) {
      await jump(playlist.index);
    } else {
      _playlistController.add(state.playlist);
    }
  }

  /// Starts playing the [Player].
  Future<void> play() async {
    await _completer.future;
    var name = 'playlist-pos-1'.toNativeUtf8();
    final pos = calloc<Int64>();
    mpv.mpv_get_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_INT64,
      pos.cast(),
    );
    if (pos.value <= 0 ||
        (pos.value == 1 && state.position == Duration.zero) ||
        state.isCompleted) {
      jump(0);
    }
    calloc.free(name);
    name = 'pause'.toNativeUtf8();
    final flag = calloc<Int8>();
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
    final name = 'pause'.toNativeUtf8();
    final flag = calloc<Int8>();
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
    await _command(
      [
        'loadfile',
        media.uri,
        'append',
        null,
      ],
    );
    state.playlist.medias.add(media);
    _playlistController.add(state.playlist);
  }

  /// Removes the [Media] at specified index from the [Player]'s playlist.
  Future<void> remove(int index) async {
    await _completer.future;
    await _command(
      [
        'playlist-remove',
        index.toString(),
      ],
    );
    state.playlist.medias.removeAt(index);
    _playlistController.add(state.playlist);
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  Future<void> next() async {
    await _completer.future;
    await _command(
      [
        'playlist-next',
      ],
    );
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  Future<void> back() async {
    await _completer.future;
    await _command(
      [
        'playlist-prev',
      ],
    );
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  Future<void> jump(int index) async {
    await _completer.future;
    var name = 'playlist-pos-1'.toNativeUtf8();
    final value = calloc<Int64>()..value = index + 1;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_INT64,
      value.cast(),
    );
    calloc.free(name);
    name = 'pause'.toNativeUtf8();
    final flag = calloc<Int8>();
    flag.value = 0;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
    calloc.free(value);
    state.playlist.index = index;
    _playlistController.add(state.playlist);
  }

  /// Moves the playlist [Media] at [from], so that it takes the place of the [Media] [to].
  Future<void> move(int from, int to) async {
    await _completer.future;
    await _command(
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
    final args = [
      'seek',
      (duration.inMilliseconds / 1000).toStringAsFixed(4).toString(),
      'absolute',
    ].join(' ').toNativeUtf8();
    mpv.mpv_command_string(
      _handle,
      args.cast(),
    );
    calloc.free(args);
  }

  /// Sets playlist mode.
  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {
    await _completer.future;
    final loopFile = 'loop-file'.toNativeUtf8();
    final loopPlaylist = 'loop-playlist'.toNativeUtf8();
    final yes = calloc<Int8>();
    yes.value = 1;
    final no = calloc<Int8>();
    no.value = 0;
    switch (playlistMode) {
      case PlaylistMode.none:
        {
          mpv.mpv_set_property(
            handle,
            loopFile.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            no.cast(),
          );
          mpv.mpv_set_property(
            handle,
            loopPlaylist.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            no.cast(),
          );
          break;
        }
      case PlaylistMode.single:
        {
          mpv.mpv_set_property(
            handle,
            loopFile.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            yes.cast(),
          );
          mpv.mpv_set_property(
            handle,
            loopPlaylist.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            no.cast(),
          );
          break;
        }
      case PlaylistMode.loop:
        {
          mpv.mpv_set_property(
            handle,
            loopFile.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            no.cast(),
          );
          mpv.mpv_set_property(
            handle,
            loopPlaylist.cast(),
            generated.mpv_format.MPV_FORMAT_FLAG,
            yes.cast(),
          );
          break;
        }
      default:
        break;
    }
    calloc.free(loopFile);
    calloc.free(loopPlaylist);
    calloc.free(yes);
    calloc.free(no);
  }

  /// Sets the playback volume of the [Player]. Defaults to `100.0`.
  set volume(double volume) {
    () async {
      await _completer.future;
      final name = 'volume'.toNativeUtf8();
      final value = calloc<Double>();
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
      final name = 'speed'.toNativeUtf8();
      final value = calloc<Double>();
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
      await _command(
        [
          shuffle ? 'playlist-shuffle' : 'playlist-unshuffle',
        ],
      );
      final name = 'playlist'.toNativeUtf8();
      final data = calloc<generated.mpv_node>();
      mpv.mpv_get_property(
        handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_NODE,
        data.cast(),
      );
      try {
        // Shuffling updates the order of [state.playlist]. Fetching latest playlist from MPV & updating Dart stream.
        if (data.ref.format == generated.mpv_format.MPV_FORMAT_NODE_ARRAY) {
          final playlist = <Media>[];
          for (int i = 0; i < data.ref.u.list.ref.num; i++) {
            if (data.ref.u.list.ref.values[i].format ==
                generated.mpv_format.MPV_FORMAT_NODE_MAP) {
              for (int j = 0;
                  j < data.ref.u.list.ref.values[i].u.list.ref.num;
                  j++) {
                if (data.ref.u.list.ref.values[i].u.list.ref.values[j].format ==
                    generated.mpv_format.MPV_FORMAT_STRING) {
                  final property = data
                      .ref.u.list.ref.values[i].u.list.ref.keys[j]
                      .cast<Utf8>()
                      .toDartString();
                  if (property == 'filename') {
                    final value = data
                        .ref.u.list.ref.values[i].u.list.ref.values[j].u.string
                        .cast<Utf8>()
                        .toDartString();
                    playlist.add(medias[value]!);
                  }
                }
              }
            }
          }
          state.playlist.medias = playlist;
          _playlistController.add(state.playlist);
          calloc.free(name);
          calloc.free(data);
        }
      } catch (exception, stacktrace) {
        print(exception);
        print(stacktrace);
        await _command(
          [
            'playlist-unshuffle',
          ],
        );
      }
    }();
  }

  Future<void> _create() async {
    if (libmpv == null) return;
    streams = _PlayerStreams(
      [
        _playlistController,
        _isPlayingController,
        _isCompletedController,
        _positionController,
        _durationController,
        _volumeController,
        _rateController,
        _isBufferingController,
        _errorController,
      ],
    );
    _handle = await create(
      libmpv!,
      (event) async {
        _error(event.ref.error);
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
          state.isCompleted = false;
          state.isPlaying = true;
          if (!_isCompletedController.isClosed) {
            _isCompletedController.add(false);
          }
          if (!_isPlayingController.isClosed) {
            _isPlayingController.add(true);
          }
        }
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
          // Check for `mpv_end_file_reason.MPV_END_FILE_REASON_EOF` before
          // modifying `state.isCompleted`.
          // Thanks to <github.com/DomingoMG> for noticing the bug.
          if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason ==
              generated.mpv_end_file_reason.MPV_END_FILE_REASON_EOF) {
            state.isCompleted = true;
            state.isPlaying = false;
            if (!_isCompletedController.isClosed) {
              _isCompletedController.add(true);
            }
            if (!_isPlayingController.isClosed) {
              _isPlayingController.add(false);
            }
          }
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          final prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            final isPlaying = prop.ref.data.cast<Int8>().value != 1;
            state.isPlaying = isPlaying;
            if (!_isPlayingController.isClosed) {
              _isPlayingController.add(isPlaying);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'paused-for-cache' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            final isBuffering = prop.ref.data.cast<Int8>().value != 0;
            state.isBuffering = isBuffering;
            if (!_isBufferingController.isClosed) {
              _isBufferingController.add(isBuffering);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'time-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            final position = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.position = position;
            if (!_positionController.isClosed) {
              _positionController.add(position);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'duration' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            final duration = Duration(
                microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
            state.duration = duration;
            if (!_durationController.isClosed) {
              _durationController.add(duration);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist-pos-1' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
            final index = prop.ref.data.cast<Int64>().value - 1;
            state.playlist.index = index;
            if (!_playlistController.isClosed) {
              _playlistController.add(state.playlist);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'volume' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            final volume = prop.ref.data.cast<Double>().value;
            state.volume = volume;
            if (!_volumeController.isClosed) {
              _volumeController.add(volume);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'speed' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            final rate = prop.ref.data.cast<Double>().value;
            state.rate = rate;
            if (!_rateController.isClosed) {
              _rateController.add(rate);
            }
          }
        }
      },
    );
    final properties = <String, int>{
      'pause': generated.mpv_format.MPV_FORMAT_FLAG,
      'time-pos': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'playlist-pos-1': generated.mpv_format.MPV_FORMAT_INT64,
      'seekable': generated.mpv_format.MPV_FORMAT_FLAG,
      'volume': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'speed': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'paused-for-cache': generated.mpv_format.MPV_FORMAT_FLAG,
    };
    properties.forEach((property, format) {
      final ptr = property.toNativeUtf8();
      mpv.mpv_observe_property(
        _handle,
        0,
        ptr.cast(),
        format,
      );
      calloc.free(ptr);
    });
    <String, int>{
      'demuxer-max-bytes': 4096000,
      'demuxer-max-back-bytes': 4096000,
    }.forEach((key, value) {
      final _key = key.toNativeUtf8();
      final _value = calloc<Int64>()..value = value;
      mpv.mpv_set_property(
        _handle,
        _key.cast(),
        generated.mpv_format.MPV_FORMAT_INT64,
        _value.cast(),
      );
      calloc.free(_key);
      calloc.free(_value);
    });
    if (!video) {
      final vo = 'vo'.toNativeUtf8();
      final osd = 'osd'.toNativeUtf8();
      final value = 'null'.toNativeUtf8();
      mpv.mpv_set_option_string(
        _handle,
        vo.cast(),
        value.cast(),
      );
      mpv.mpv_set_option_string(
        _handle,
        osd.cast(),
        value.cast(),
      );
      calloc.free(vo);
      calloc.free(osd);
      calloc.free(value);
    }
    if (osc) {
      final name = 'osc'.toNativeUtf8();
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
    if (title != null) {
      final name = 'title'.toNativeUtf8();
      final value = title!.toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    final cache = 'cache'.toNativeUtf8();
    final no = 'no'.toNativeUtf8();
    mpv.mpv_set_property_string(
      _handle,
      cache.cast(),
      no.cast(),
    );
    calloc.free(cache);
    calloc.free(no);
    _completer.complete();
  }

  /// Adds an error to the [Player.stream.error].
  void _error(int code) {
    if (code < 0 && !_errorController.isClosed) {
      _errorController.add(
        _PlayerError(
          code,
          mpv.mpv_error_string(code).cast<Utf8>().toDartString(),
        ),
      );
    }
  }

  /// Calls MPV command passed as [args]. Automatically freeds memory after command sending.
  ///
  /// An [Isolate] is used to prevent blocking of the main thread during native-type marshalling.
  Future<void> _command(List<String?> args) async {
    final completer = Completer<void>();
    final receiver = ReceivePort()
      ..listen((value) {
        if (value == true) {
          completer.complete();
        }
      });
    final isolate = await Isolate.spawn(
      _mpvCommandIsolate,
      [
        libmpv!,
        _handle.address,
        receiver.sendPort,
        ...args,
      ],
    );
    await completer.future;
    isolate.kill();
    receiver.close();
  }

  /// Whether video is visible or not.
  final bool video;

  /// Whether on screen controls are visible or not.
  final bool osc;

  /// User defined window title for the MPV instance.
  final String? title;

  /// cross-fade [Duration].
  Duration crossfade;

  /// YouTube daemon to serve links.
  YouTube? youtube;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// [Completer] used to ensure initialization of [generated.mpv_handle] & synchronization on another isolate.
  final Completer<void> _completer = Completer();

  /// Internally used [StreamController].
  final StreamController<Playlist> _playlistController =
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
  final StreamController<double> _volumeController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<double> _rateController = StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> _isBufferingController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<_PlayerError> _errorController =
      StreamController.broadcast();
}

/// Private class to raise errors by the [Player].
class _PlayerError {
  final int id;
  final String message;

  _PlayerError(this.id, this.message);
}

/// Private class to keep state of the [Player].
class _PlayerState {
  /// [List] of currently opened [Media]s.
  Playlist playlist = Playlist([]);

  /// If the [Player] is playing.
  bool isPlaying = false;

  /// If the [Player]'s playback is completed.
  bool isCompleted = false;

  /// Current playback position of the [Player].
  Duration position = Duration.zero;

  /// Duration of the currently playing [Media] in the [Player].
  Duration duration = Duration.zero;

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

  /// Current volume of the [Player].
  late Stream<double> volume;

  /// Current playback rate of the [Player].
  late Stream<double> rate;

  /// Whether the [Player] has stopped for buffering.
  late Stream<bool> isBuffering;

  /// [Stream] raising [_PlayerError]s.
  late Stream<_PlayerError> error;

  _PlayerStreams(List<StreamController> controllers) {
    playlist = controllers[0].stream.cast();
    isPlaying = controllers[1].stream.cast();
    isCompleted = controllers[2].stream.cast();
    position = controllers[3].stream.cast();
    duration = controllers[4].stream.cast();
    volume = controllers[5].stream.cast();
    rate = controllers[6].stream.cast();
    isBuffering = controllers[7].stream.cast();
    error = controllers[8].stream.cast();
  }
}

/// Calls MPV command passed as [args]. Automatically freeds memory after command sending.
///
/// Contents of [args] should be:
///
/// * `args[0]` should be the dynamic library path.
/// * `args[1]` should be the `mpv_handle` pointer address as [int].
/// * `args[2]` should be [SendPort] that receives the confirmation of command completion.
/// * Following arguments should be the command to be sent to MPV.
Future<void> _mpvCommandIsolate(List<dynamic> args) async {
  Pointer<Utf8> toNativeUtf8(String e) {
    final units = utf8.encode(e);
    final Pointer<Uint8> result = malloc(units.length + 1);
    final nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }

  final List<Pointer<Utf8>> pointers = args.skip(3).map<Pointer<Utf8>>((e) {
    if (e == null) return nullptr.cast();
    return toNativeUtf8(e);
  }).toList();
  final Pointer<Pointer<Utf8>> arr =
      calloc.allocate(args.skip(3).join().length);
  for (int i = 0; i < args.skip(3).length; i++) {
    arr[i] = pointers[i];
  }
  DynamicLibrary.open(args[0])
      .lookupFunction<
          Int32 Function(Pointer<generated.mpv_handle>, Pointer<Pointer<Int8>>),
          int Function(Pointer<generated.mpv_handle>,
              Pointer<Pointer<Int8>>)>('mpv_command')
      .call(
        Pointer.fromAddress(args[1]),
        arr.cast(),
      );
  calloc.free(arr);
  pointers.forEach(calloc.free);
  (args[2] as SendPort).send(true);
}

/// Calls MPV command `loadfile` with multiple media [Uri]s passed as String in [arguments].
/// Automatically freeds memory after command sending.
///
/// Contents of [arguments] should be:
///
/// * `args[0]` should be the dynamic library path.
/// * `args[1]` should be the `mpv_handle` pointer address as [int].
/// * `args[2]` should be [SendPort] that receives the confirmation of command completion.
/// * Following arguments should be media [Uri]s passed as [String].
Future<void> _mpvCommandLoadFileIsolate(List<dynamic> arguments) async {
  Pointer<Utf8> toNativeUtf8(String e) {
    final units = utf8.encode(e);
    final Pointer<Uint8> result = malloc(units.length + 1);
    final nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }

  void mpvCommand(List<String> args) {
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      return toNativeUtf8(e);
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    DynamicLibrary.open(arguments[0])
        .lookupFunction<
            Int32 Function(
                Pointer<generated.mpv_handle>, Pointer<Pointer<Int8>>),
            int Function(Pointer<generated.mpv_handle>,
                Pointer<Pointer<Int8>>)>('mpv_command')
        .call(
          Pointer.fromAddress(arguments[1]),
          arr.cast(),
        );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  mpvCommand(
    [
      'playlist-play-index',
      'none',
    ],
  );
  mpvCommand(
    [
      'playlist-clear',
    ],
  );
  for (final uri in arguments.skip(3)) {
    mpvCommand(
      [
        'loadfile',
        uri,
        'append',
      ],
    );
  }
  (arguments[2] as SendPort).send(true);
}
