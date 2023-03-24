/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';
import 'dart:async';
import 'package:ffi/ffi.dart';

import 'package:media_kit/src/platform_player.dart';
import 'package:media_kit/src/libmpv/core/initializer.dart';
import 'package:media_kit/src/libmpv/core/native_library.dart';
import 'package:media_kit/src/libmpv/core/fallback_bitrate_handler.dart';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/player_error.dart';
import 'package:media_kit/src/models/player_log.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

import 'package:media_kit/generated/libmpv/bindings.dart' as generated;

/// {@template libmpv_player}
///
/// Player
/// ------
///
/// Compatiblity has been tested with libmpv 0.28.0 or higher. The recommended version is 0.33.0 or higher.
///
/// {@endtemplate}
class Player extends PlatformPlayer {
  /// {@macro libmpv_player}
  Player({required super.configuration}) {
    _create().then((_) {
      configuration.ready?.call();
    });
  }

  /// Disposes the [Player] instance & releases the resources.
  @override
  Future<void> dispose({int code = 0}) async {
    final ctx = await _handle.future;
    // Raw `mpv_command` calls cause crash on Windows.
    final command = 'quit $code'.toNativeUtf8();
    _libmpv?.mpv_command_string(
      ctx,
      command.cast(),
    );
    calloc.free(command);
    super.dispose();
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
  @override
  Future<void> open(
    Playlist playlist, {
    bool play = true,
    bool evictCache = true,
  }) async {
    if (evictCache) {
      // Clean-up existing cached [medias].
      medias.clear();
      bitrates.clear();
      // Restore current playlist.
      for (final media in playlist.medias) {
        medias[media.uri] = media;
        medias[Media.getCleanedURI(media.uri)] = media;
      }
    }
    final ctx = await _handle.future;
    // Clean-up existing playlist & change currently playing libmpv index to `none`.
    // This causes playback to stop & player to enter `idle` state.
    final commands = [
      'stop'.toNativeUtf8(),
      'playlist-clear'.toNativeUtf8(),
      'playlist-play-index none'.toNativeUtf8(),
    ];
    for (final command in commands) {
      _libmpv?.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command);
    }
    await _unpause();
    for (final media in playlist.medias) {
      await _command(
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
    // Thanks to @DomingoMG for the fix!
    state = state.copyWith(
      playlist: playlist,
      isPlaying: play,
    );
    // To wait for the index change [jump] call.
    if (!playlistController.isClosed) {
      playlistController.add(state.playlist);
    }
    if (!isPlayingController.isClosed) {
      isPlayingController.add(state.isPlaying);
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
  @override
  Future<void> play() async {
    final ctx = await _handle.future;
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
      _libmpv?.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        flag.cast(),
      );
      calloc.free(name);
      calloc.free(flag);
    }
  }

  /// Pauses the [Player].
  @override
  Future<void> pause() async {
    final ctx = await _handle.future;
    _isPlaybackEverStarted = true;
    state = state.copyWith(isPlaying: false);
    final name = 'pause'.toNativeUtf8();
    final flag = calloc<Int8>();
    flag.value = 1;
    _libmpv?.mpv_set_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
  }

  /// Cycles between [play] & [pause] states of the [Player].
  @override
  Future<void> playOrPause() async {
    final ctx = await _handle.future;
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
    _libmpv?.mpv_command_string(
      ctx,
      command.cast(),
    );
    calloc.free(command);
  }

  /// Appends a [Media] to the [Player]'s playlist.
  @override
  Future<void> add(Media media) async {
    await _command(
      [
        'loadfile',
        media.uri,
        'append',
        null,
      ],
    );
    state.playlist.medias.add(media);
    if (!playlistController.isClosed) {
      playlistController.add(state.playlist);
    }
  }

  /// Removes the [Media] at specified index from the [Player]'s playlist.
  @override
  Future<void> remove(int index) async {
    await _command(
      [
        'playlist-remove',
        index.toString(),
      ],
    );
    state.playlist.medias.removeAt(index);
    if (!playlistController.isClosed) {
      playlistController.add(state.playlist);
    }
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  @override
  Future<void> next() async {
    final ctx = await _handle.future;
    // Use `mpv_command_string` as `mpv_command` seems
    // to randomly cause a crash on older libmpv versions.
    if (_isPlaybackEverStarted && !state.isCompleted) {
      final next = 'playlist-next'.toNativeUtf8();
      _libmpv?.mpv_command_string(
        ctx,
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
    await _unpause();
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  @override
  Future<void> previous() async {
    final ctx = await _handle.future;
    // Use `mpv_command_string` as `mpv_command` seems
    // to randomly cause a crash on older libmpv versions.
    if (_isPlaybackEverStarted && !state.isCompleted) {
      final next = 'playlist-prev'.toNativeUtf8();
      _libmpv?.mpv_command_string(
        ctx,
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
    await _unpause();
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  @override
  Future<void> jump(
    int index, {
    bool open = false,
  }) async {
    final ctx = await _handle.future;
    _isPlaybackEverStarted = true;
    state = state.copyWith(
      playlist: state.playlist.copyWith(
        index: index,
      ),
    );
    if (!playlistController.isClosed) {
      playlistController.add(state.playlist);
    }
    var name = 'playlist-pos'.toNativeUtf8();
    final value = calloc<Int64>()..value = index;
    _libmpv?.mpv_set_property(
      ctx,
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
    _libmpv?.mpv_set_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      flag.cast(),
    );
    calloc.free(name);
    calloc.free(flag);
    calloc.free(value);
  }

  /// Moves the playlist [Media] at [from], so that it takes the place of the [Media] [to].
  @override
  Future<void> move(int from, int to) async {
    await _command(
      [
        'playlist-move',
        from.toString(),
        to.toString(),
      ],
    );
    state.playlist.medias.insert(to, state.playlist.medias.removeAt(from));
    playlistController.add(state.playlist);
  }

  /// Seeks the currently playing [Media] in the [Player] by specified [Duration].
  @override
  Future<void> seek(Duration duration) async {
    final ctx = await _handle.future;
    // Raw `mpv_command` calls cause crash on Windows.
    final args = [
      'seek',
      (duration.inMilliseconds / 1000).toStringAsFixed(4).toString(),
      'absolute',
    ].join(' ').toNativeUtf8();
    _libmpv?.mpv_command_string(
      ctx,
      args.cast(),
    );
    calloc.free(args);
  }

  /// Sets playlist mode.
  @override
  Future<void> setPlaylistMode(PlaylistMode playlistMode) async {
    final ctx = await _handle.future;
    final loopFile = 'loop-file'.toNativeUtf8();
    final loopPlaylist = 'loop-playlist'.toNativeUtf8();
    final yes = 'yes'.toNativeUtf8();
    final no = 'no'.toNativeUtf8();
    switch (playlistMode) {
      case PlaylistMode.none:
        {
          _libmpv?.mpv_set_property_string(
            ctx,
            loopFile.cast(),
            no.cast(),
          );
          _libmpv?.mpv_set_property_string(
            ctx,
            loopPlaylist.cast(),
            no.cast(),
          );
          break;
        }
      case PlaylistMode.single:
        {
          _libmpv?.mpv_set_property_string(
            ctx,
            loopFile.cast(),
            yes.cast(),
          );
          _libmpv?.mpv_set_property_string(
            ctx,
            loopPlaylist.cast(),
            no.cast(),
          );
          break;
        }
      case PlaylistMode.loop:
        {
          _libmpv?.mpv_set_property_string(
            ctx,
            loopFile.cast(),
            no.cast(),
          );
          _libmpv?.mpv_set_property_string(
            ctx,
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
  @override
  set volume(double volume) {
    () async {
      final ctx = await _handle.future;
      final name = 'volume'.toNativeUtf8();
      final value = calloc<Double>();
      value.value = volume;
      _libmpv?.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_DOUBLE,
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }();
  }

  /// Sets the playback rate of the [Player]. Defaults to `1.0`.
  @override
  set rate(double rate) {
    () async {
      if (configuration.pitch) {
        // Pitch shift control is enabled.
        final ctx = await _handle.future;
        state = state.copyWith(
          rate: rate,
        );
        if (!rateController.isClosed) {
          rateController.add(state.rate);
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
        _libmpv?.mpv_set_property_string(
          ctx,
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
        _libmpv?.mpv_set_property_string(
          ctx,
          name.cast(),
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      } else {
        // Pitch shift control is disabled.
        final ctx = await _handle.future;
        state = state.copyWith(
          rate: rate,
        );
        if (!rateController.isClosed) {
          rateController.add(state.rate);
        }
        final name = 'speed'.toNativeUtf8();
        final value = calloc<Double>();
        value.value = rate;
        _libmpv?.mpv_set_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_DOUBLE,
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      }
    }();
  }

  /// Sets the relative pitch of the [Player]. Defaults to `1.0`.
  @override
  set pitch(double pitch) {
    () async {
      if (configuration.pitch) {
        // Pitch shift control is enabled.
        final ctx = await _handle.future;
        state = state.copyWith(
          pitch: pitch,
        );
        if (!pitchController.isClosed) {
          pitchController.add(state.pitch);
        }
        // Rubberband Library is expensive.
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
        // _libmpv?.mpv_set_property(
        //   ctx,
        //   name.cast(),
        //   generated.mpv_format.MPV_FORMAT_NODE,
        //   data.cast(),
        // );
        // calloc.free(name);
        // _libmpv?.mpv_free_node_contents(data);
        var name = 'audio-pitch-correction'.toNativeUtf8();
        final no = 'no'.toNativeUtf8();
        _libmpv?.mpv_set_property_string(
          ctx,
          name.cast(),
          no.cast(),
        );
        calloc.free(name);
        calloc.free(no);
        name = 'speed'.toNativeUtf8();
        final speed = calloc<Double>()..value = pitch;
        _libmpv?.mpv_set_property(
          ctx,
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
        _libmpv?.mpv_set_property_string(
          ctx,
          name.cast(),
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      } else {
        // Pitch shift control is disabled.
        throw Exception('[PlayerConfiguration.pitch] is false.');
      }
    }();
  }

  /// Enables or disables shuffle for [Player]. Default is `false`.
  @override
  set shuffle(bool shuffle) {
    () async {
      final ctx = await _handle.future;
      if (!_isPlaybackEverStarted) {
        await play();
        return;
      }
      await _command(
        [
          shuffle ? 'playlist-shuffle' : 'playlist-unshuffle',
        ],
      );
      final name = 'playlist'.toNativeUtf8();
      final data = calloc<generated.mpv_node>();
      _libmpv?.mpv_get_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_NODE,
        data.cast(),
      );
      try {
        // Shuffling updates the order of [state.playlist]. Fetching latest playlist from mpv & updating Dart stream.
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
          state = state.copyWith(
            playlist: state.playlist.copyWith(
              medias: playlist,
            ),
          );
          if (!playlistController.isClosed) {
            playlistController.add(state.playlist);
          }
          // Free the memory allocated by `mpv_get_property`.
          _libmpv?.mpv_free_node_contents(data);
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

  /// Sets current [AudioDevice].
  set audioDevice(FutureOr<AudioDevice> device) {
    () async {
      final result = await device;
      final ctx = await _handle.future;
      final name = 'audio-device'.toNativeUtf8();
      final value = result.name.toNativeUtf8();
      final ptr = calloc<Pointer<Utf8>>();
      ptr.value = value;
      _libmpv?.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_STRING,
        ptr.cast(),
      );
      calloc.free(name);
      calloc.free(value);
      calloc.free(ptr);
    }();
  }

  /// Gets current [AudioDevice].
  FutureOr<AudioDevice> get audioDevice async {
    final ctx = await _handle.future;
    final name = 'audio-device'.toNativeUtf8();
    final value = calloc<Pointer<Utf8>>();
    _libmpv?.mpv_get_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_STRING,
      value.cast(),
    );
    final devices = await availableAudioDevices;
    final result = devices.firstWhere(
      (element) => element.name == value.value.cast<Utf8>().toDartString(),
    );
    calloc.free(name);
    // Free the memory allocated by `mpv_get_property`.
    _libmpv?.mpv_free(value.value.cast());
    calloc.free(value);
    return result;
  }

  /// Get the list of all the available [AudioDevice]s.
  Future<List<AudioDevice>> get availableAudioDevices async {
    final ctx = await _handle.future;
    final name = 'audio-device-list'.toNativeUtf8();
    final value = calloc<generated.mpv_node>();
    _libmpv?.mpv_get_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_NODE,
      value.cast(),
    );
    final result = <AudioDevice>[];
    if (value.ref.format == generated.mpv_format.MPV_FORMAT_NODE_ARRAY) {
      final list = value.ref.u.list.ref;
      for (int i = 0; i < list.num; i++) {
        if (list.values[i].format == generated.mpv_format.MPV_FORMAT_NODE_MAP) {
          String name = '', description = '';
          final device = list.values[i].u.list.ref;
          for (int j = 0; j < device.num; j++) {
            if (device.values[j].format ==
                generated.mpv_format.MPV_FORMAT_STRING) {
              final property = device.keys[j].cast<Utf8>().toDartString();
              final value =
                  device.values[j].u.string.cast<Utf8>().toDartString();
              switch (property) {
                case 'name':
                  name = value;
                  break;
                case 'description':
                  description = value;
                  break;
              }
            }
          }
          result.add(AudioDevice(name, description));
        }
      }
    }
    // Free the memory allocated by `mpv_get_property`.
    _libmpv?.mpv_free_node_contents(value);
    calloc.free(name);
    calloc.free(value);
    return result;
  }

  /// [generated.mpv_handle] address of the internal libmpv player instance.
  @override
  Future<int> get handle async {
    final pointer = await _handle.future;
    return pointer.address;
  }

  /// Sets property / option for the internal `libmpv` instance of this [Player].
  /// Please use this method only if you know what you are doing, existing methods in [Player] implementation are suited for the most use cases.
  ///
  /// See:
  /// * https://mpv.io/manual/master/#options
  /// * https://mpv.io/manual/master/#properties
  ///
  Future<void> setProperty(String property, String value) async {
    final ctx = await _handle.future;
    final name = property.toNativeUtf8();
    final data = value.toNativeUtf8();
    _libmpv?.mpv_set_property_string(
      ctx,
      name.cast(),
      data.cast(),
    );
    calloc.free(name);
    calloc.free(data);
  }

  Future<void> _handler(Pointer<generated.mpv_event> event) async {
    _error(event.ref.error);
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
      state = state.copyWith(
        isCompleted: false,
      );
      if (_isPlaybackEverStarted) {
        state = state.copyWith(
          isPlaying: true,
        );
      }
      if (!isCompletedController.isClosed) {
        isCompletedController.add(false);
      }
      if (!isPlayingController.isClosed && _isPlaybackEverStarted) {
        isPlayingController.add(true);
      }
    }
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
      // Check for `mpv_end_file_reason.MPV_END_FILE_REASON_EOF` before modifying `state.isCompleted`.
      // Thanks to @DomingoMG for noticing the bug.
      if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason ==
          generated.mpv_end_file_reason.MPV_END_FILE_REASON_EOF) {
        state = state.copyWith(
          isCompleted: true,
        );
        if (_isPlaybackEverStarted) {
          state = state.copyWith(
            isPlaying: false,
          );
        }
        if (!isCompletedController.isClosed) {
          isCompletedController.add(true);
        }
        if (!isPlayingController.isClosed && _isPlaybackEverStarted) {
          isPlayingController.add(false);
        }
        if (!audioParamsController.isClosed) {
          audioParamsController.add(const AudioParams());
          state = state.copyWith(audioParams: const AudioParams());
        }
        if (!audioBitrateController.isClosed) {
          audioBitrateController.add(null);
          state = state.copyWith(audioBitrate: null);
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
          state = state.copyWith(isPlaying: isPlaying);
          if (!isPlayingController.isClosed) {
            isPlayingController.add(isPlaying);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'paused-for-cache' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        final isBuffering = prop.ref.data.cast<Int8>().value != 0;
        state = state.copyWith(isBuffering: isBuffering);
        if (!isBufferingController.isClosed) {
          isBufferingController.add(isBuffering);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'time-pos' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        final position = Duration(
            microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
        state = state.copyWith(position: position);
        if (!positionController.isClosed) {
          positionController.add(position);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'duration' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        final duration = Duration(
            microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1);
        state = state.copyWith(duration: duration);
        if (!durationController.isClosed) {
          durationController.add(duration);
        }
        // NOTE: Using manual bitrate calculation for FLAC.
        // Too much going on here. Enclosing in a try-catch block.
        try {
          if (state.playlist.index >= 0 &&
              state.playlist.index < state.playlist.medias.length) {
            final uri = state.playlist.medias[state.playlist.index].uri;
            if (FallbackBitrateHandler.isLocalFLACOrOGGFile(uri)) {
              if (!bitrates.containsKey(uri) ||
                  !bitrates.containsKey(Media.getCleanedURI(uri))) {
                bitrates[uri] = await FallbackBitrateHandler.calculateBitrate(
                  uri,
                  duration,
                );
              }
              final bitrate = bitrates[uri];
              if (bitrate != null) {
                state = state.copyWith(audioBitrate: bitrate);
                if (!audioBitrateController.isClosed) {
                  audioBitrateController.add(bitrate);
                }
              }
            }
          }
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist-pos' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
        final index = prop.ref.data.cast<Int64>().value;
        if (_isPlaybackEverStarted) {
          state = state.copyWith(
            playlist: state.playlist.copyWith(
              index: index,
            ),
          );
          if (!playlistController.isClosed) {
            playlistController.add(state.playlist);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'volume' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        final volume = prop.ref.data.cast<Double>().value;
        state = state.copyWith(volume: volume);
        if (!volumeController.isClosed) {
          volumeController.add(volume);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-params' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final data = prop.ref.data.cast<generated.mpv_node>();
        final params = <String, dynamic>{};
        for (int i = 0; i < data.ref.u.list.ref.num; i++) {
          final key = data.ref.u.list.ref.keys[i].cast<Utf8>().toDartString();

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
        state = state.copyWith(
          audioParams: AudioParams(
            format: params['format'],
            sampleRate: params['samplerate'],
            channels: params['channels'],
            channelCount: params['channel-count'],
            hrChannels: params['hr-channels'],
          ),
        );
        if (!audioParamsController.isClosed) {
          audioParamsController.add(state.audioParams);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-bitrate' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        // Too much going on here. Enclosing in a try-catch block.
        try {
          if (state.playlist.index < state.playlist.medias.length &&
              state.playlist.index >= 0) {
            final data = prop.ref.data.cast<Double>().value;
            final uri = state.playlist.medias[state.playlist.index].uri;
            // NOTE: Using manual bitrate calculation for FLAC.
            if (!FallbackBitrateHandler.isLocalFLACOrOGGFile(uri)) {
              if (!bitrates.containsKey(uri) ||
                  !bitrates.containsKey(Media.getCleanedURI(uri))) {
                bitrates[uri] = data;
                bitrates[Media.getCleanedURI(uri)] = data;
              }
              final bitrate =
                  bitrates[uri] ?? bitrates[Media.getCleanedURI(uri)];
              if (!audioBitrateController.isClosed &&
                  bitrate != state.audioBitrate) {
                audioBitrateController.add(bitrate);
                state = state.copyWith(audioBitrate: bitrate);
              }
            }
          } else {
            if (!audioBitrateController.isClosed) {
              audioBitrateController.add(null);
              state = state.copyWith(audioBitrate: null);
            }
          }
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
      }
      // See [rate] & [pitch] setters/getters.
      // Handled manually using `scaletempo`.
      // if (prop.ref.name.cast<Utf8>().toDartString() == 'speed' &&
      //     prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
      //   final rate = prop.ref.data.cast<Double>().value;
      //   state.rate = rate;
      //   if (!rateController.isClosed) {
      //     rateController.add(rate);
      //   }
      // }
    }
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_LOG_MESSAGE) {
      final eventLogMessage =
          event.ref.data.cast<generated.mpv_event_log_message>().ref;

      final prefix = eventLogMessage.prefix.cast<Utf8>().toDartString().trim();
      final level = eventLogMessage.level.cast<Utf8>().toDartString().trim();
      final text = eventLogMessage.text.cast<Utf8>().toDartString().trim();

      if (!logController.isClosed) {
        logController.add(
          PlayerLog(
            prefix: prefix,
            level: level,
            text: text,
          ),
        );
      }
    }
  }

  Future<void> _create() async {
    _libmpv = generated.MPV(NativeLibrary.find(path: configuration.libmpv));
    final result = await create(
      configuration.libmpv,
      configuration.events ? _handler : null,
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
    }.forEach(
      (property, format) {
        final ptr = property.toNativeUtf8();
        _libmpv?.mpv_observe_property(
          result,
          0,
          ptr.cast(),
          format,
        );
        calloc.free(ptr);
      },
    );
    // No longer explicitly setting demuxer cache size.
    // Though, it may cause rise in memory usage but still it is certainly better
    // than files randomly stuttering or seeking to a random position on their own.
    // <String, int>{
    //   'demuxer-max-bytes': 8192000,
    //   'demuxer-max-back-bytes': 8192000,
    // }.forEach((key, value) {
    //   final _key = key.toNativeUtf8();
    //   final _value = calloc<Int64>()..value = value;
    //   _libmpv?.mpv_set_property(
    //     result,
    //     _key.cast(),
    //     generated.mpv_format.MPV_FORMAT_INT64,
    //     _value.cast(),
    //   );
    //   calloc.free(_key);
    //   calloc.free(_value);
    // });
    if (!configuration.osc) {
      <String, String>{
        'osc': 'no',
        'osd-level': '0',
      }.forEach((property, value) {
        final ptr = property.toNativeUtf8();
        final val = value.toNativeUtf8();
        _libmpv?.mpv_set_property_string(
          result,
          ptr.cast(),
          val.cast(),
        );
        calloc.free(ptr);
        calloc.free(val);
      });
    }
    if (configuration.vid != null) {
      final name = 'vid'.toNativeUtf8();
      final flag = calloc<Int8>();
      flag.value = configuration.vid! ? 1 : 0;
      _libmpv?.mpv_set_property(
        result,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        flag.cast(),
      );
      calloc.free(name);
      calloc.free(flag);
    }
    if (configuration.vo != null) {
      final name = 'vo'.toNativeUtf8();
      final value = configuration.vo!.toNativeUtf8();
      _libmpv?.mpv_set_property_string(
        result,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    if (configuration.title != null) {
      final name = 'title'.toNativeUtf8();
      final value = configuration.title!.toNativeUtf8();
      _libmpv?.mpv_set_property_string(
        result,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }
    if (configuration.events && configuration.logLevel != MPVLogLevel.none) {
      // https://github.com/mpv-player/mpv/blob/e1727553f164181265f71a20106fbd5e34fa08b0/libmpv/client.h#L1410-L1419
      final levels = {
        MPVLogLevel.none: "no",
        MPVLogLevel.fatal: "fatal",
        MPVLogLevel.error: "error",
        MPVLogLevel.warn: "warn",
        MPVLogLevel.info: "info",
        MPVLogLevel.v: "v",
        MPVLogLevel.debug: "debug",
        MPVLogLevel.trace: "trace",
      };

      final level = levels[configuration.logLevel];
      if (level != null) {
        final minLevel = level.toNativeUtf8();
        _libmpv?.mpv_request_log_messages(
          result,
          minLevel.cast(),
        );
        calloc.free(minLevel);
      }
    }
    final name = 'idle'.toNativeUtf8();
    final value = calloc<Int32>();
    value.value = 1;
    _libmpv?.mpv_set_property(
      result,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    _handle.complete(result);
  }

  /// Adds an error to the [Player.stream.error].
  void _error(int code) {
    if (code < 0 && !errorController.isClosed) {
      final message =
          _libmpv?.mpv_error_string(code).cast<Utf8>().toDartString();
      if (message != null) {
        errorController.add(
          PlayerError(
            code,
            message,
          ),
        );
      }
    }
  }

  /// Calls mpv command passed as [args]. Automatically freeds memory after command sending.
  Future<void> _command(List<String?> args) async {
    final ctx = await _handle.future;
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      if (e == null) return nullptr.cast();
      return e.toNativeUtf8();
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    _libmpv?.mpv_command(
      ctx,
      arr.cast(),
    );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  Future<void> _unpause() async {
    final ctx = await _handle.future;
    // We do not want the player to be in `paused` state before opening a new playlist or jumping to new index.
    // We are only changing the `pause` property to `false` if it wasn't already `false` because this can cause problems with older libmpv versions.
    final name = 'pause'.toNativeUtf8();
    final data = calloc<Bool>();
    _libmpv?.mpv_get_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_FLAG,
      data.cast(),
    );
    if (data.value) {
      data.value = false;
      _libmpv?.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        data.cast(),
      );
    }
    calloc.free(name);
    calloc.free(data);
  }

  /// Internal generated libmpv C API bindings.
  generated.MPV? _libmpv;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  final Completer<Pointer<generated.mpv_handle>> _handle =
      Completer<Pointer<generated.mpv_handle>>();

  /// libmpv API hack, to prevent [state.isPlaying] getting changed due to volume or rate being changed.
  bool _isPlaybackEverStarted = false;
}
