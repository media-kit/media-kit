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
import 'package:media_kit/src/models/track.dart';
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
      playing: play,
    );
    // To wait for the index change [jump] call.
    if (!playlistController.isClosed) {
      playlistController.add(state.playlist);
    }
    if (!playingController.isClosed) {
      playingController.add(state.playing);
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
      if (state.playing) return;
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
    state = state.copyWith(playing: false);
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
    else if (state.completed) {
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
    if (_isPlaybackEverStarted && !state.completed) {
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
    if (_isPlaybackEverStarted && !state.completed) {
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
  Future<void> setVolume(double volume) async {
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
  }

  /// Sets the playback rate of the [Player]. Defaults to `1.0`.
  @override
  Future<void> setRate(double rate) async {
    if (configuration.pitch) {
      // Pitch shift control is enabled.
      final ctx = await _handle.future;
      state = state.copyWith(
        rate: rate,
      );
      if (!rateController.isClosed) {
        rateController.add(state.rate);
      }
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
  }

  /// Sets the relative pitch of the [Player]. Defaults to `1.0`.
  @override
  Future<void> setPitch(double pitch) async {
    if (configuration.pitch) {
      // Pitch shift control is enabled.
      final ctx = await _handle.future;
      state = state.copyWith(
        pitch: pitch,
      );
      if (!pitchController.isClosed) {
        pitchController.add(state.pitch);
      }
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
  }

  /// Enables or disables shuffle for [Player]. Default is `false`.
  @override
  Future<void> setShuffle(bool shuffle) async {
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
  }

  /// Sets the current [AudioDevice] for audio output.
  ///
  /// * Currently selected [AudioDevice] can be accessed using [state.audioDevice] or [streams.audioDevice].
  /// * The list of currently available [AudioDevice]s can be obtained accessed using [state.audioDevices] or [streams.audioDevices].
  @override
  FutureOr<void> setAudioDevice(AudioDevice audioDevice) async {
    final ctx = await _handle.future;
    final name = 'audio-device'.toNativeUtf8();
    final value = audioDevice.name.toNativeUtf8();
    _libmpv?.mpv_set_property(
      ctx,
      name.cast(),
      generated.mpv_format.MPV_FORMAT_STRING,
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
  }

  /// Sets the current [VideoTrack] for video output.
  ///
  /// * Currently selected [VideoTrack] can be accessed using [state.track.video] or [streams.track.video].
  /// * The list of currently available [VideoTrack]s can be obtained accessed using [state.tracks.video] or [streams.tracks.video].
  @override
  FutureOr<void> setVideoTrack(VideoTrack track) async {
    final ctx = await _handle.future;
    final name = 'vid'.toNativeUtf8();
    final value = track.id.toNativeUtf8();
    _libmpv?.mpv_set_property_string(
      ctx,
      name.cast(),
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    state = state.copyWith(
      track: state.track.copyWith(
        video: track,
      ),
    );
    if (!trackController.isClosed) {
      trackController.add(state.track);
    }
  }

  /// Sets the current [AudioTrack] for audio output.
  ///
  /// * Currently selected [AudioTrack] can be accessed using [state.track.audio] or [streams.track.audio].
  /// * The list of currently available [AudioTrack]s can be obtained accessed using [state.tracks.audio] or [streams.tracks.audio].
  @override
  FutureOr<void> setAudioTrack(AudioTrack track) async {
    final ctx = await _handle.future;
    final name = 'aid'.toNativeUtf8();
    final value = track.id.toNativeUtf8();
    _libmpv?.mpv_set_property_string(
      ctx,
      name.cast(),
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    state = state.copyWith(
      track: state.track.copyWith(
        audio: track,
      ),
    );
    if (!trackController.isClosed) {
      trackController.add(state.track);
    }
  }

  /// Sets the current [SubtitleTrack] for subtitle output.
  ///
  /// * Currently selected [SubtitleTrack] can be accessed using [state.track.subtitle] or [streams.track.subtitle].
  /// * The list of currently available [SubtitleTrack]s can be obtained accessed using [state.tracks.subtitle] or [streams.tracks.subtitle].
  @override
  FutureOr<void> setSubtitleTrack(SubtitleTrack track) async {
    final ctx = await _handle.future;
    final name = 'sid'.toNativeUtf8();
    final value = track.id.toNativeUtf8();
    _libmpv?.mpv_set_property_string(
      ctx,
      name.cast(),
      value.cast(),
    );
    calloc.free(name);
    calloc.free(value);
    state = state.copyWith(
      track: state.track.copyWith(
        subtitle: track,
      ),
    );
    if (!trackController.isClosed) {
      trackController.add(state.track);
    }
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
        completed: false,
      );
      if (_isPlaybackEverStarted) {
        state = state.copyWith(
          playing: true,
        );
      }
      if (!completedController.isClosed) {
        completedController.add(false);
      }
      if (!playingController.isClosed && _isPlaybackEverStarted) {
        playingController.add(true);
      }
    }
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
      // Check for `mpv_end_file_reason.MPV_END_FILE_REASON_EOF` before modifying `state.completed`.
      // Thanks to @DomingoMG for noticing the bug.
      if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason ==
          generated.mpv_end_file_reason.MPV_END_FILE_REASON_EOF) {
        state = state.copyWith(
          completed: true,
        );
        if (_isPlaybackEverStarted) {
          state = state.copyWith(
            playing: false,
          );
        }
        if (!completedController.isClosed) {
          completedController.add(true);
        }
        if (!playingController.isClosed && _isPlaybackEverStarted) {
          playingController.add(false);
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
          final playing = prop.ref.data.cast<Int8>().value != 1;
          state = state.copyWith(playing: playing);
          if (!playingController.isClosed) {
            playingController.add(playing);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'paused-for-cache' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        final buffering = prop.ref.data.cast<Int8>().value != 0;
        state = state.copyWith(buffering: buffering);
        if (!bufferingController.isClosed) {
          bufferingController.add(buffering);
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
            final bitrate = bitrates[uri] ?? bitrates[Media.getCleanedURI(uri)];
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
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-device' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final value = prop.ref.data.cast<generated.mpv_node>();
        if (value.ref.format == generated.mpv_format.MPV_FORMAT_STRING) {
          final name = value.ref.u.string.cast<Utf8>().toDartString();
          final audioDevice = AudioDevice(name, '');
          state = state.copyWith(audioDevice: audioDevice);
          if (!audioDeviceController.isClosed) {
            audioDeviceController.add(audioDevice);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'audio-device-list' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final value = prop.ref.data.cast<generated.mpv_node>();
        final audioDevices = <AudioDevice>[];
        if (value.ref.format == generated.mpv_format.MPV_FORMAT_NODE_ARRAY) {
          final list = value.ref.u.list.ref;
          for (int i = 0; i < list.num; i++) {
            if (list.values[i].format ==
                generated.mpv_format.MPV_FORMAT_NODE_MAP) {
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
              audioDevices.add(AudioDevice(name, description));
            }
          }
          state = state.copyWith(audioDevices: audioDevices);
          if (!audioDevicesController.isClosed) {
            audioDevicesController.add(audioDevices);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'track-list' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final value = prop.ref.data.cast<generated.mpv_node>();
        if (value.ref.format == generated.mpv_format.MPV_FORMAT_NODE_ARRAY) {
          final video = [VideoTrack.auto(), VideoTrack.no()];
          final audio = [AudioTrack.auto(), AudioTrack.no()];
          final subtitle = [SubtitleTrack.auto(), SubtitleTrack.no()];

          final tracks = value.ref.u.list.ref;

          for (int i = 0; i < tracks.num; i++) {
            if (tracks.values[i].format ==
                generated.mpv_format.MPV_FORMAT_NODE_MAP) {
              final map = tracks.values[i].u.list.ref;
              String id = '';
              String type = '';
              String? title;
              String? lang;
              for (int j = 0; j < map.num; j++) {
                final property = map.keys[j].cast<Utf8>().toDartString();
                if (map.values[j].format ==
                    generated.mpv_format.MPV_FORMAT_INT64) {
                  if (property == 'id') {
                    id = map.values[j].u.int64.toString();
                  }
                }
                if (map.values[j].format ==
                    generated.mpv_format.MPV_FORMAT_STRING) {
                  final value =
                      map.values[j].u.string.cast<Utf8>().toDartString();
                  switch (property) {
                    case 'type':
                      type = value;
                      break;
                    case 'title':
                      title = value;
                      break;
                    case 'lang':
                      lang = value;
                      break;
                  }
                }
              }
              switch (type) {
                case 'video':
                  video.add(VideoTrack(id, title, lang));
                  break;
                case 'audio':
                  audio.add(AudioTrack(id, title, lang));
                  break;
                case 'sub':
                  subtitle.add(SubtitleTrack(id, title, lang));
                  break;
              }
            }
          }

          state = state.copyWith(
            tracks: Tracks(
              video: video,
              audio: audio,
              subtitle: subtitle,
            ),
            // Remove selections which are not in the list anymore.
            track: Track(
              video: video.contains(state.track.video)
                  ? state.track.video
                  : VideoTrack.auto(),
              audio: audio.contains(state.track.audio)
                  ? state.track.audio
                  : AudioTrack.auto(),
              subtitle: subtitle.contains(state.track.subtitle)
                  ? state.track.subtitle
                  : SubtitleTrack.auto(),
            ),
          );

          if (!tracksController.isClosed) {
            tracksController.add(state.tracks);
          }
          if (!trackController.isClosed) {
            trackController.add(state.track);
          }
        }
      }
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
      'audio-device': generated.mpv_format.MPV_FORMAT_NODE,
      'audio-device-list': generated.mpv_format.MPV_FORMAT_NODE,
      'track-list': generated.mpv_format.MPV_FORMAT_NODE,
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
        MPVLogLevel.none: 'no',
        MPVLogLevel.fatal: 'fatal',
        MPVLogLevel.error: 'error',
        MPVLogLevel.warn: 'warn',
        MPVLogLevel.info: 'info',
        MPVLogLevel.v: 'v',
        MPVLogLevel.debug: 'debug',
        MPVLogLevel.trace: 'trace',
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

  /// libmpv API hack, to prevent [state.playing] getting changed due to volume or rate being changed.
  bool _isPlaybackEverStarted = false;
}
