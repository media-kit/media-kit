/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

import 'package:media_kit/src/dynamic_library.dart';
import 'package:media_kit/src/core/initializer.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

import 'package:media_kit/generated/bindings.dart' as generated;

import 'package:media_kit/src/plugins/youtube.dart';

/// ## Player
///
/// [Player] class provides high-level abstraction for media playback.
/// Large number of features have been exposed as class methods & properties.
///
/// The [Player]'s instantaneous state may be read using the [state] attribute
/// & subscription to the them may be made using the [streams] available.
///
/// The loaded libmpv version by this class may be queried using the [version] attribute
/// & RAW C/C++ [mpv_handle] may be accessed using the [handle].
/// Compatiblity has been tested with libmpv 0.28.0 or higher. The recommended version is 0.33.0 or higher.
/// Call [dispose] to free the resources back to the system.
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
///   play: false,
/// );
/// player.play();
/// ```
///
class Player {
  /// ## Player
  ///
  /// [Player] class provides high-level abstraction for media playback.
  /// Large number of features have been exposed as class methods & properties.
  ///
  /// The [Player]'s instantaneous state may be read using the [state] attribute
  /// & subscription to the them may be made using the [streams] available.
  ///
  /// The loaded libmpv version by this class may be queried using the [version] attribute
  /// & RAW C/C++ [mpv_handle] may be accessed using the [handle].
  /// Compatiblity has been tested with libmpv 0.28.0 or higher. The recommended version is 0.33.0 or higher.
  /// Call [dispose] to free the resources back to the system.
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
  ///   play: false,
  /// );
  /// player.play();
  /// ```
  ///
  Player({
    this.video = false,
    this.osc = false,
    this.maxVolume = 200.0,
    bool yt = true,
    this.title,
    void Function(Player)? onCreate,
  }) {
    if (yt) {
      youtube = YouTube.instance;
    }
    _create().then(
      (_) => onCreate?.call(this),
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
    // Raw `mpv_command` calls cause crash on Windows.
    final args = [
      'quit',
      '$code',
    ].join(' ').toNativeUtf8();
    mpv.mpv_command_string(
      _handle,
      args.cast(),
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
  /// Pass [play] as `true` to automatically start playback.
  /// Otherwise, [Player.play] must be called manually afterwards.
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
    bool clearCache = true,
  }) async {
    if (clearCache) {
      // Clean-up existing cached [medias].
      medias.clear();
      bitrates.clear();
      // Restore current playlist.
      for (final media in playlist.medias) {
        medias[media.uri] = media;
        medias[Media.getCleanedURI(media.uri)] = media;
      }
    }
    await _completer.future;
    // Clean-up existing playlist & change currently playing libmpv index to `none`.
    // This causes playback to stop & player to enter `idle` state.
    final commands = [
      'stop'.toNativeUtf8(),
      'playlist-clear'.toNativeUtf8(),
      'playlist-play-index none'.toNativeUtf8(),
    ];
    for (final command in commands) {
      mpv.mpv_command_string(
        _handle,
        command.cast(),
      );
      calloc.free(command);
    }
    _unpause();
    for (final media in playlist.medias) {
      _command(
        [
          'loadfile',
          media.uri,
          'append',
        ],
      );
    }
    // Even though `replace` parameter in `loadfile` automatically causes the
    // [Media] to play but in certain cases like, where a [Media] is paused & then
    // new [Media] is [Player.open]ed it causes [Media] to not starting playing
    // automatically.
    // Thanks to <github.com/DomingoMG> for the fix!
    state.playlist = playlist;
    state.isPlaying = play;
    // To wait for the index change [jump] call.
    if (!_playlistController.isClosed) {
      _playlistController.add(state.playlist);
    }
    if (!_isPlayingController.isClosed) {
      _isPlayingController.add(state.isPlaying);
    }
    _isPlaybackEverStarted = false;
    if (play) {
      await jump(
        playlist.index,
        open: true,
      );
    }
  }

  /// Starts playing the [Player].
  Future<void> play() async {
    await _completer.future;
    if (!_isPlaybackEverStarted) {
      _isPlaybackEverStarted = true;
      final bounds = state.playlist.index < state.playlist.medias.length &&
          state.playlist.index >= 0;
      await jump(
        bounds ? state.playlist.index : 0,
        open: true,
      );
    } else {
      if (state.isPlaying) return;
      _isPlaybackEverStarted = true;
      final name = 'pause'.toNativeUtf8();
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
  }

  /// Pauses the [Player].
  Future<void> pause() async {
    await _completer.future;
    _isPlaybackEverStarted = true;
    state.isPlaying = false;
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

  /// Cycles between [play] & [pause] states of the [Player].
  Future<void> playOrPause() async {
    await _completer.future;
    if (!_isPlaybackEverStarted) {
      await play();
      return;
    }
    // This condition will occur when [PlaylistMode.none] is set & all playback of a [Playlist] is completed.
    // Thus, when user presses the play/pause button, we must start playing the [Playlist] from the beginning.
    // Otherwise the button just freezes.
    else if (state.isCompleted) {
      await jump(0, open: true);
      return;
    }
    final command = 'cycle pause'.toNativeUtf8();
    mpv.mpv_command_string(
      _handle,
      command.cast(),
    );
    calloc.free(command);
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
    state.playlist.medias.add(media);
    if (!_playlistController.isClosed) {
      _playlistController.add(state.playlist);
    }
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
    state.playlist.medias.removeAt(index);
    if (!_playlistController.isClosed) {
      _playlistController.add(state.playlist);
    }
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  Future<void> next() async {
    await _completer.future;
    // Use `mpv_command_string` as `mpv_command` seems
    // to randomly cause a crash on older libmpv versions.
    if (_isPlaybackEverStarted && !state.isCompleted) {
      final next = 'playlist-next'.toNativeUtf8();
      mpv.mpv_command_string(
        _handle,
        next.cast(),
      );
      calloc.free(next);
    } else {
      await jump(
        (state.playlist.index + 1).clamp(
          0,
          state.playlist.medias.length,
        ),
        open: true,
      );
    }
    _unpause();
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  Future<void> previous() async {
    await _completer.future;
    // Use `mpv_command_string` as `mpv_command` seems
    // to randomly cause a crash on older libmpv versions.
    if (_isPlaybackEverStarted && !state.isCompleted) {
      final next = 'playlist-prev'.toNativeUtf8();
      mpv.mpv_command_string(
        _handle,
        next.cast(),
      );
      calloc.free(next);
    } else {
      await jump(
        (state.playlist.index - 1).clamp(
          0,
          state.playlist.medias.length,
        ),
        open: true,
      );
    }
    _unpause();
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  Future<void> jump(
    int index, {
    bool open = false,
  }) async {
    await _completer.future;
    _isPlaybackEverStarted = true;
    state.playlist.index = index;
    if (!_playlistController.isClosed) {
      _playlistController.add(state.playlist);
    }
    var name = 'playlist-pos'.toNativeUtf8();
    final value = calloc<Int64>()..value = index;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_INT64,
      value.cast(),
    );
    calloc.free(name);
    if (open) {
      return;
    }
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
    state.playlist.medias.insert(to, state.playlist.medias.removeAt(from));
    _playlistController.add(state.playlist);
  }

  /// Seeks the currently playing [Media] in the [Player] by specified [Duration].
  Future<void> seek(Duration duration) async {
    await _completer.future;
    // Raw `mpv_command` calls cause crash on Windows.
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
    final yes = 'yes'.toNativeUtf8();
    final no = 'no'.toNativeUtf8();
    switch (playlistMode) {
      case PlaylistMode.none:
        {
          mpv.mpv_set_property_string(
            handle,
            loopFile.cast(),
            no.cast(),
          );
          mpv.mpv_set_property_string(
            handle,
            loopPlaylist.cast(),
            no.cast(),
          );
          break;
        }
      case PlaylistMode.single:
        {
          mpv.mpv_set_property_string(
            handle,
            loopFile.cast(),
            yes.cast(),
          );
          mpv.mpv_set_property_string(
            handle,
            loopPlaylist.cast(),
            no.cast(),
          );
          break;
        }
      case PlaylistMode.loop:
        {
          mpv.mpv_set_property_string(
            handle,
            loopFile.cast(),
            no.cast(),
          );
          mpv.mpv_set_property_string(
            handle,
            loopPlaylist.cast(),
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
  /// Resets [pitch] to `1.0`.
  set rate(double rate) {
    () async {
      await _completer.future;
      state.rate = rate;
      if (!_rateController.isClosed) {
        _rateController.add(state.rate);
      }
      // No `rubberband` is available.
      // Apparently, using `scaletempo:scale` actually controls the playback rate
      // as intended after setting `audio-pitch-correction` as `FALSE`.
      // `speed` on the other hand, changes the pitch when `audio-pitch-correction`
      // is set to `FALSE`. Since, it also alters the actual [speed], the
      // `scaletempo:scale` is divided by the same value of [pitch] to compensate the
      // speed change.
      var name = 'audio-pitch-correction'.toNativeUtf8();
      final no = 'no'.toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        name.cast(),
        no.cast(),
      );
      calloc.free(name);
      calloc.free(no);
      name = 'af'.toNativeUtf8();
      // Divide by [state.pitch] to compensate the speed change caused by pitch shift.
      final value =
          'scaletempo:scale=${(state.rate / state.pitch).toStringAsFixed(8)}'
              .toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }();
  }

  /// Sets the relative pitch of the [Player]. Defaults to `1.0`.
  set pitch(double pitch) {
    () async {
      await _completer.future;
      state.pitch = pitch;
      if (!_pitchController.isClosed) {
        _pitchController.add(state.pitch);
      }
      // `rubberband` is not bundled in `libmpv` shared library at the moment. GPL.
      // Using `scaletempo` instead.
      // final name = 'af'.toNativeUtf8();
      // final keys = calloc<Pointer<Utf8>>(2);
      // final paramKeys = calloc<Pointer<Utf8>>(2);
      // final paramValues = calloc<Pointer<Utf8>>(2);
      // paramKeys[0] = 'key'.toNativeUtf8();
      // paramKeys[1] = 'value'.toNativeUtf8();
      // paramValues[0] = 'pitch-scale'.toNativeUtf8();
      // paramValues[1] = pitch.toStringAsFixed(8).toNativeUtf8();
      // final values = calloc<Pointer<generated.mpv_node>>(2);
      // keys[0] = 'name'.toNativeUtf8();
      // keys[1] = 'params'.toNativeUtf8();
      // values[0] = calloc<generated.mpv_node>();
      // values[0].ref.format = generated.mpv_format.MPV_FORMAT_STRING;
      // values[0].ref.u.string = 'rubberband'.toNativeUtf8().cast();
      // values[1] = calloc<generated.mpv_node>();
      // values[1].ref.format = generated.mpv_format.MPV_FORMAT_NODE_MAP;
      // values[1].ref.u.list = calloc<generated.mpv_node_list>();
      // values[1].ref.u.list.ref.num = 2;
      // values[1].ref.u.list.ref.keys = paramKeys.cast();
      // values[1].ref.u.list.ref.values = paramValues.cast();
      // final data = calloc<generated.mpv_node>();
      // data.ref.format = generated.mpv_format.MPV_FORMAT_NODE_ARRAY;
      // data.ref.u.list = calloc<generated.mpv_node_list>();
      // data.ref.u.list.ref.num = 1;
      // data.ref.u.list.ref.values = calloc<generated.mpv_node>();
      // data.ref.u.list.ref.values.ref.format =
      //     generated.mpv_format.MPV_FORMAT_NODE_MAP;
      // data.ref.u.list.ref.values.ref.u.list = calloc<generated.mpv_node_list>();
      // data.ref.u.list.ref.values.ref.u.list.ref.num = 2;
      // data.ref.u.list.ref.values.ref.u.list.ref.keys = keys.cast();
      // data.ref.u.list.ref.values.ref.u.list.ref.values = values.cast();
      // mpv.mpv_set_property(
      //   _handle,
      //   name.cast(),
      //   generated.mpv_format.MPV_FORMAT_NODE,
      //   data.cast(),
      // );
      // calloc.free(name);
      // mpv.mpv_free_node_contents(data);
      var name = 'audio-pitch-correction'.toNativeUtf8();
      final no = 'no'.toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        name.cast(),
        no.cast(),
      );
      calloc.free(name);
      calloc.free(no);
      name = 'speed'.toNativeUtf8();
      final speed = calloc<Double>()..value = pitch;
      mpv.mpv_set_property(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_DOUBLE,
        speed.cast(),
      );
      calloc.free(name);
      calloc.free(speed);
      name = 'af'.toNativeUtf8();
      // Divide by [state.pitch] to compensate the speed change caused by pitch shift.
      final value =
          'scaletempo:scale=${(state.rate / state.pitch).toStringAsFixed(8)}'
              .toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        name.cast(),
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
          if (!_playlistController.isClosed) {
            _playlistController.add(state.playlist);
          }
          calloc.free(name);
          calloc.free(data);
        }
      } catch (exception, stacktrace) {
        print(exception);
        print(stacktrace);
        _command(
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
      _playlistController.stream,
      _isPlayingController.stream,
      _isCompletedController.stream,
      _positionController.stream,
      _durationController.stream,
      _volumeController.stream,
      _rateController.stream,
      _pitchController.stream,
      _isBufferingController.stream,
      _errorController.stream,
      _audioParamsController.stream,
      _audioBitrateController.stream,
    );
    _handle = await create(
      libmpv!,
      (event) async {
        // print(
        //   mpv.mpv_event_name(event.ref.event_id).cast<Utf8>().toDartString(),
        // );
        _error(event.ref.error);
        if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
          state.isCompleted = false;
          if (_isPlaybackEverStarted) {
            state.isPlaying = true;
          }
          if (!_isCompletedController.isClosed) {
            _isCompletedController.add(false);
          }
          if (!_isPlayingController.isClosed && _isPlaybackEverStarted) {
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
            if (_isPlaybackEverStarted) {
              state.isPlaying = false;
            }
            if (!_isCompletedController.isClosed) {
              _isCompletedController.add(true);
            }
            if (!_isPlayingController.isClosed && _isPlaybackEverStarted) {
              _isPlayingController.add(false);
            }
            if (!_audioParamsController.isClosed) {
              _audioParamsController.add(
                AudioParams(null, null, null, null, null),
              );
              state.audioParams = AudioParams(
                null,
                null,
                null,
                null,
                null,
              );
            }
            if (!_audioBitrateController.isClosed) {
              _audioBitrateController.add(null);
              state.audioBitrate = null;
            }
          }
        }
        if (event.ref.event_id ==
            generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
          final prop = event.ref.data.cast<generated.mpv_event_property>();
          if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
            if (_isPlaybackEverStarted) {
              final isPlaying = prop.ref.data.cast<Int8>().value != 1;
              state.isPlaying = isPlaying;
              if (!_isPlayingController.isClosed) {
                _isPlayingController.add(isPlaying);
              }
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
          if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist-pos' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
            bitrates.clear();
            final index = prop.ref.data.cast<Int64>().value;
            if (_isPlaybackEverStarted) {
              state.playlist.index = index;
              if (!_playlistController.isClosed) {
                _playlistController.add(state.playlist);
              }
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
          if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-params' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
            final data = prop.ref.data.cast<generated.mpv_node>();
            final params = <String, dynamic>{};
            for (int i = 0; i < data.ref.u.list.ref.num; i++) {
              final key =
                  data.ref.u.list.ref.keys[i].cast<Utf8>().toDartString();

              switch (key) {
                case 'format':
                  {
                    params[key] = data.ref.u.list.ref.values[i].u.string
                        .cast<Utf8>()
                        .toDartString();
                    break;
                  }
                case 'samplerate':
                  {
                    params[key] = data.ref.u.list.ref.values[i].u.int64;
                    break;
                  }
                case 'channels':
                  {
                    params[key] = data.ref.u.list.ref.values[i].u.string
                        .cast<Utf8>()
                        .toDartString();
                    break;
                  }
                case 'channel-count':
                  {
                    params[key] = data.ref.u.list.ref.values[i].u.int64;
                    break;
                  }
                case 'hr-channels':
                  {
                    params[key] = data.ref.u.list.ref.values[i].u.string
                        .cast<Utf8>()
                        .toDartString();
                    break;
                  }
                default:
                  {
                    break;
                  }
              }
            }
            state.audioParams = AudioParams(
              params['format'],
              params['samplerate'],
              params['channels'],
              params['channel-count'],
              params['hr-channels'],
            );
            if (!_audioParamsController.isClosed) {
              _audioParamsController.add(state.audioParams);
            }
          }
          if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-bitrate' &&
              prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
            if (state.playlist.index < state.playlist.medias.length &&
                state.playlist.index >= 0) {
              final data = prop.ref.data.cast<Double>().value;
              final uri = state.playlist.medias[state.playlist.index].uri;
              if (!bitrates.containsKey(uri) ||
                  !bitrates.containsKey(Media.getCleanedURI(uri))) {
                bitrates[uri] = data;
                bitrates[Media.getCleanedURI(uri)] = data;
              }
              if (!_audioBitrateController.isClosed &&
                  (bitrates[uri] ?? bitrates[Media.getCleanedURI(uri)]) !=
                      state.audioBitrate) {
                _audioBitrateController.add(
                  bitrates[uri] ?? bitrates[Media.getCleanedURI(uri)],
                );
                state.audioBitrate =
                    bitrates[uri] ?? bitrates[Media.getCleanedURI(uri)];
              }
            } else {
              if (!_audioBitrateController.isClosed) {
                _audioBitrateController.add(null);
                state.audioBitrate = null;
              }
            }
          }
          // See [rate] & [pitch] setters/getters.
          // Handled manually using `scaletempo`.
          // if (prop.ref.name.cast<Utf8>().toDartString() == 'speed' &&
          //     prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
          //   final rate = prop.ref.data.cast<Double>().value;
          //   state.rate = rate;
          //   if (!_rateController.isClosed) {
          //     _rateController.add(rate);
          //   }
          // }
        }
      },
    );
    <String, int>{
      'pause': generated.mpv_format.MPV_FORMAT_FLAG,
      'time-pos': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'playlist-pos': generated.mpv_format.MPV_FORMAT_INT64,
      'seekable': generated.mpv_format.MPV_FORMAT_FLAG,
      'volume': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'speed': generated.mpv_format.MPV_FORMAT_DOUBLE,
      'paused-for-cache': generated.mpv_format.MPV_FORMAT_FLAG,
      'audio-params': generated.mpv_format.MPV_FORMAT_NODE,
      'audio-bitrate': generated.mpv_format.MPV_FORMAT_DOUBLE,
    }.forEach((property, format) {
      final ptr = property.toNativeUtf8();
      mpv.mpv_observe_property(
        _handle,
        0,
        ptr.cast(),
        format,
      );
      calloc.free(ptr);
    });
    // No longer explicitly setting demuxer cache size.
    // Though, it may cause rise in memory usage but still it is certainly better
    // than files randomly stuttering or seeking to a random position on their own.
    // <String, int>{
    //   'demuxer-max-bytes': 8192000,
    //   'demuxer-max-back-bytes': 8192000,
    // }.forEach((key, value) {
    //   final _key = key.toNativeUtf8();
    //   final _value = calloc<Int64>()..value = value;
    //   mpv.mpv_set_property(
    //     _handle,
    //     _key.cast(),
    //     generated.mpv_format.MPV_FORMAT_INT64,
    //     _value.cast(),
    //   );
    //   calloc.free(_key);
    //   calloc.free(_value);
    // });
    if (!video) {
      final vo = 'vo'.toNativeUtf8();
      final osd = 'osd'.toNativeUtf8();
      final value = 'null'.toNativeUtf8();
      mpv.mpv_set_property_string(
        _handle,
        vo.cast(),
        value.cast(),
      );
      mpv.mpv_set_property_string(
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
    // No longer explicitly setting demuxer cache size.
    // Though, it may cause rise in memory usage but still it is certainly better
    // than files randomly stuttering or seeking to a random position on their own.
    // final cache = 'cache'.toNativeUtf8();
    // final no = 'no'.toNativeUtf8();
    // mpv.mpv_set_property_string(
    //   _handle,
    //   cache.cast(),
    //   no.cast(),
    // );
    // calloc.free(cache);
    // calloc.free(no);
    var name = 'volume-max'.toNativeUtf8();
    final value = calloc<Double>()..value = maxVolume.toDouble();
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_DOUBLE,
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    try {
      final name = 'mpv-version'.toNativeUtf8();
      version = mpv
          .mpv_get_property_string(
            _handle,
            name.cast(),
          )
          .cast<Utf8>()
          .toDartString();
      calloc.free(name);
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
    }
    name = 'idle'.toNativeUtf8();
    final flag = calloc<Int32>()..value = 1;
    mpv.mpv_set_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
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
  void _command(List<String?> args) {
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      if (e == null) return nullptr.cast();
      return e.toNativeUtf8();
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    mpv.mpv_command(
      _handle,
      arr.cast(),
    );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  void _unpause() {
    // We do not want the player to be in `paused` state before opening a new playlist or jumping to new index.
    // We are only changing the `pause` property to `false` if it wasn't already `false` because this can cause problems with older libmpv versions.
    final name = 'pause'.toNativeUtf8();
    final data = calloc<Bool>();
    mpv.mpv_get_property(
      _handle,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      data.cast(),
    );
    if (data.value) {
      data.value = false;
      mpv.mpv_set_property(
        _handle,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        data.cast(),
      );
    }
    calloc.free(name);
    calloc.free(data);
  }

  /// Whether video is visible or not.
  final bool video;

  /// Whether on screen controls are visible or not.
  final bool osc;

  /// User defined window title for the MPV instance.
  final String? title;

  /// Maximum volume that can be assigned to this [Player].
  /// Used for volume boost.
  final double maxVolume;

  /// YouTube daemon to serve links.
  YouTube? youtube;

  /// mpv version which is powering this [Player] internally.
  String? version;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  late Pointer<generated.mpv_handle> _handle;

  /// libmpv API hack, to prevent [state.isPlaying] getting changed due to volume or rate being changed.
  bool _isPlaybackEverStarted = false;

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
  final StreamController<double> _pitchController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<bool> _isBufferingController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<_PlayerError> _errorController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<AudioParams> _audioParamsController =
      StreamController.broadcast();

  /// Internally used [StreamController].
  final StreamController<double?> _audioBitrateController =
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

  /// Current pitch of the [Player].
  double pitch = 1.0;

  /// Whether the [Player] has stopped for buffering.
  bool isBuffering = false;

  /// Audio parameters of the currently playing [Media].
  /// e.g. sample rate, channels, etc.
  AudioParams audioParams = AudioParams(
    null,
    null,
    null,
    null,
    null,
  );

  /// Audio bitrate of the currently playing [Media].
  double? audioBitrate;
}

/// Private class for event handling of [Player].
class _PlayerStreams {
  /// [List] of currently opened [Media]s.
  final Stream<Playlist> playlist;

  /// If the [Player] is playing.
  final Stream<bool> isPlaying;

  /// If the [Player]'s playback is completed.
  final Stream<bool> isCompleted;

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
  final Stream<bool> isBuffering;

  /// [Stream] raising [_PlayerError]s.
  final Stream<_PlayerError> error;

  /// [Stream] used to get audio parameters like sample rate, format & channels etc.
  final Stream<AudioParams> audioParams;

  /// Audio bitrate of the currently playing [Media] in the [Player].
  final Stream<double?> audioBitrate;

  _PlayerStreams(
    this.playlist,
    this.isPlaying,
    this.isCompleted,
    this.position,
    this.duration,
    this.volume,
    this.rate,
    this.pitch,
    this.isBuffering,
    this.error,
    this.audioParams,
    this.audioBitrate,
  );
}
