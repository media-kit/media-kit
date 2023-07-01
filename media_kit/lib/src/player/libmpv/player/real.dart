/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: camel_case_types
import 'dart:io';
import 'dart:ffi';
import 'dart:async';
import 'dart:collection';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';
import 'package:meta/meta.dart';

import 'package:media_kit/src/player/platform_player.dart';
import 'package:media_kit/src/player/libmpv/core/initializer.dart';
import 'package:media_kit/src/player/libmpv/core/native_library.dart';
import 'package:media_kit/src/player/libmpv/core/fallback_bitrate_handler.dart';
import 'package:media_kit/src/player/libmpv/core/initializer_native_event_loop.dart';

import 'package:media_kit/src/utils/lock_ext.dart';
import 'package:media_kit/src/utils/task_queue.dart';
import 'package:media_kit/src/utils/android_helper.dart';
import 'package:media_kit/src/utils/android_asset_loader.dart';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/player_log.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/player_state.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

import 'package:media_kit/generated/libmpv/bindings.dart' as generated;

/// Initializes the libmpv backend for package:media_kit.
void libmpvEnsureInitialized({String? libmpv}) {
  AndroidHelper.ensureInitialized();
  NativeLibrary.ensureInitialized(libmpv: libmpv);
  InitializerNativeEventLoop.ensureInitialized();
}

/// {@template libmpv_player}
///
/// libmpvPlayer
/// ------------
///
/// libmpv based implementation of [PlatformPlayer].
///
/// {@endtemplate}
class libmpvPlayer extends PlatformPlayer {
  /// {@macro libmpv_player}
  libmpvPlayer({required super.configuration})
      : mpv = generated.MPV(DynamicLibrary.open(NativeLibrary.path)) {
    _create().then((_) {
      configuration.ready?.call();
    });
  }

  /// Disposes the [Player] instance & releases the resources.
  @override
  Future<void> dispose({bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      await pause(synchronized: false);

      disposed = true;

      await super.dispose();

      Initializer.dispose(ctx);

      if (terminate) {
        TaskQueue.instance.add(
          () {
            bool safe = lock.count == 0 &&
                DateTime.now().difference(lock.time) >
                    TaskQueue.instance.refractoryDuration;
            if (safe) {
              print('media_kit: mpv_terminate_destroy: ${ctx.address}');
              mpv.mpv_terminate_destroy(ctx);
            }
            return safe;
          },
        );
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
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
  /// );
  /// ```
  ///
  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final int index;
      final List<Media> playlist = <Media>[];
      if (playable is Media) {
        index = 0;
        playlist.add(playable);
      } else if (playable is Playlist) {
        index = playable.index;
        playlist.addAll(playable.medias);
      } else {
        index = -1;
      }

      final commands = [
        // Clear existing playlist & change currently playing libmpv index to none.
        // This causes playback to stop & player to enter the idle state.
        'stop',
        'playlist-clear',
        'playlist-play-index none',
      ];
      for (final command in commands) {
        final args = command.toNativeUtf8();
        mpv.mpv_command_string(
          ctx,
          args.cast(),
        );
        calloc.free(args);
      }

      // Enter paused state.
      {
        final name = 'pause'.toNativeUtf8();
        final value = calloc<Uint8>();
        mpv.mpv_get_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_FLAG,
          value.cast(),
        );
        if (value.value == 0) {
          // We are using `cycle pause` because it waits & prevents the race condition.
          final command = 'cycle pause'.toNativeUtf8();
          mpv.mpv_command_string(
            ctx,
            command.cast(),
          );
        }
        calloc.free(name);
        calloc.free(value);
        state = state.copyWith(playing: false);
        if (!playingController.isClosed) {
          playingController.add(false);
        }
      }

      isShuffleEnabled = false;
      isPlayingStateChangeAllowed = false;

      for (int i = 0; i < playlist.length; i++) {
        await _command(
          [
            'loadfile',
            playlist[i].uri,
            'append',
          ],
        );
      }

      // If [play] is `true`, then exit paused state.
      if (play) {
        isPlayingStateChangeAllowed = true;
        final name = 'pause'.toNativeUtf8();
        final value = calloc<Uint8>();
        mpv.mpv_get_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_FLAG,
          value.cast(),
        );
        if (value.value == 1) {
          // We are using `cycle pause` because it waits & prevents the race condition.
          final command = 'cycle pause'.toNativeUtf8();
          mpv.mpv_command_string(
            ctx,
            command.cast(),
          );
        }
        calloc.free(name);
        calloc.free(value);
        state = state.copyWith(playing: true);
        if (!playingController.isClosed) {
          playingController.add(true);
        }
      }

      // Jump to the specified [index] (in both cases either [play] is `true` or `false`).
      {
        final name = 'playlist-pos'.toNativeUtf8();
        final value = calloc<Int64>()..value = index;
        mpv.mpv_set_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_INT64,
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Stops the [Player].
  /// Unloads the current [Media] or [Playlist] from the [Player]. This method is similar to [dispose] but does not release the resources & [Player] is still usable.
  @override
  Future<void> stop({bool synchronized = true}) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      isShuffleEnabled = false;
      isPlayingStateChangeAllowed = false;
      isBufferingStateChangeAllowed = false;

      final commands = [
        'stop',
        'playlist-clear',
        'playlist-play-index none',
      ];
      for (final command in commands) {
        final args = command.toNativeUtf8();
        mpv.mpv_command_string(
          ctx,
          args.cast(),
        );
        calloc.free(args);
      }

      // Reset the remaining attributes.
      state = PlayerState().copyWith(
        volume: state.volume,
        rate: state.rate,
        pitch: state.pitch,
        playlistMode: state.playlistMode,
        audioDevice: state.audioDevice,
        audioDevices: state.audioDevices,
      );
      if (!playlistController.isClosed) {
        playlistController.add(Playlist([]));
      }
      if (!playingController.isClosed) {
        playingController.add(false);
      }
      if (!completedController.isClosed) {
        completedController.add(false);
      }
      if (!positionController.isClosed) {
        positionController.add(Duration.zero);
      }
      if (!durationController.isClosed) {
        durationController.add(Duration.zero);
      }
      // if (!volumeController.isClosed) {
      //   volumeController.add(0.0);
      // }
      // if (!rateController.isClosed) {
      //   rateController.add(0.0);
      // }
      // if (!pitchController.isClosed) {
      //   pitchController.add(0.0);
      // }
      if (!bufferingController.isClosed) {
        bufferingController.add(false);
      }
      if (!bufferController.isClosed) {
        bufferController.add(Duration.zero);
      }
      // if (!playlistModeController.isClosed) {
      //   playlistModeController.add(PlaylistMode.none);
      // }
      if (!audioParamsController.isClosed) {
        audioParamsController.add(const AudioParams());
      }
      if (!audioBitrateController.isClosed) {
        audioBitrateController.add(null);
      }
      // if (!audioDeviceController.isClosed) {
      //   audioDeviceController.add(AudioDevice.auto());
      // }
      // if (!audioDevicesController.isClosed) {
      //   audioDevicesController.add([AudioDevice.auto()]);
      // }
      if (!trackController.isClosed) {
        trackController.add(Track());
      }
      if (!tracksController.isClosed) {
        tracksController.add(Tracks());
      }
      if (!widthController.isClosed) {
        widthController.add(null);
      }
      if (!heightController.isClosed) {
        heightController.add(null);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Starts playing the [Player].
  @override
  Future<void> play({bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      state = state.copyWith(playing: true);
      if (!playingController.isClosed) {
        playingController.add(true);
      }

      final name = 'pause'.toNativeUtf8();
      final value = calloc<Uint8>();
      mpv.mpv_get_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        value.cast(),
      );
      if (value.value == 1) {
        await playOrPause(
          notify: false,
          synchronized: false,
        );
      }
      calloc.free(name);
      calloc.free(value);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Pauses the [Player].
  @override
  Future<void> pause({bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      state = state.copyWith(playing: false);
      if (!playingController.isClosed) {
        playingController.add(false);
      }

      final name = 'pause'.toNativeUtf8();
      final value = calloc<Uint8>();
      mpv.mpv_get_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_FLAG,
        value.cast(),
      );
      if (value.value == 0) {
        await playOrPause(
          notify: false,
          synchronized: false,
        );
      }
      calloc.free(name);
      calloc.free(value);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Cycles between [play] & [pause] states of the [Player].
  @override
  Future<void> playOrPause({
    bool notify = true,
    bool synchronized = true,
  }) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      if (notify) {
        // Do not change the [state.playing] value if [playOrPause] was called from [play] or [pause]; where the [state.playing] value is already changed.
        state = state.copyWith(
          playing: !state.playing,
        );
        if (!playingController.isClosed) {
          playingController.add(state.playing);
        }
      }

      isPlayingStateChangeAllowed = true;
      isBufferingStateChangeAllowed = false;

      // This condition is specifically for the case when the internal playlist is ended (with [PlaylistLoopMode.none]), and we want to play the playlist again if play/pause is pressed.
      if (state.completed) {
        final name = 'playlist-pos'.toNativeUtf8();
        final value = calloc<Int64>()..value = 0;
        mpv.mpv_set_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_INT64,
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      }
      final command = 'cycle pause'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Appends a [Media] to the [Player]'s playlist.
  @override
  Future<void> add(Media media, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final command = 'loadfile ${media.uri} append'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command.cast());
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Removes the [Media] at specified index from the [Player]'s playlist.
  @override
  Future<void> remove(int index, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      // If we remove the last item in the playlist while playlist mode is none or single, then playback will stop.
      // In this situation, the playlist doesn't seem to be updated, so we manually update it.
      if (state.playlist.index == index &&
          state.playlist.medias.length - 1 == index &&
          [
            PlaylistMode.none,
            PlaylistMode.single,
          ].contains(state.playlistMode)) {
        state = state.copyWith(
          // Allow playOrPause /w state.completed code-path to play the playlist again.
          completed: true,
          playlist: state.playlist.copyWith(
            medias: state.playlist.medias.sublist(
              0,
              state.playlist.medias.length - 1,
            ),
            index: state.playlist.medias.length - 2 < 0
                ? 0
                : state.playlist.medias.length - 2,
          ),
        );
        if (!completedController.isClosed) {
          completedController.add(true);
        }
        if (!playlistController.isClosed) {
          playlistController.add(state.playlist);
        }
      }

      final command = 'playlist-remove $index'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command.cast());
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Jumps to next [Media] in the [Player]'s playlist.
  @override
  Future<void> next({bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      // Do nothing if currently present at the first or last index & playlist mode is [PlaylistMode.none] or [PlaylistMode.single].
      if ([
            PlaylistMode.none,
            PlaylistMode.single,
          ].contains(state.playlistMode) &&
          state.playlist.index == state.playlist.medias.length - 1) {
        return;
      }

      await play(synchronized: false);
      final command = 'playlist-next'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Jumps to previous [Media] in the [Player]'s playlist.
  @override
  Future<void> previous({bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      // Do nothing if currently present at the first or last index & playlist mode is [PlaylistMode.none] or [PlaylistMode.single].
      if ([
            PlaylistMode.none,
            PlaylistMode.single,
          ].contains(state.playlistMode) &&
          state.playlist.index == 0) {
        return;
      }

      await play(synchronized: false);
      final command = 'playlist-prev'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Jumps to specified [Media]'s index in the [Player]'s playlist.
  @override
  Future<void> jump(int index, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      await play(synchronized: false);
      final name = 'playlist-pos'.toNativeUtf8();
      final value = calloc<Int64>()..value = index;
      mpv.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_INT64,
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Moves the playlist [Media] at [from], so that it takes the place of the [Media] [to].
  @override
  Future<void> move(int from, int to, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final command = 'playlist-move $from $to'.toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        command.cast(),
      );
      calloc.free(command.cast());
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Seeks the currently playing [Media] in the [Player] by specified [Duration].
  @override
  Future<void> seek(Duration duration, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      // Raw `mpv_command` calls cause crash on Windows.
      final args = [
        'seek',
        (duration.inMilliseconds / 1000).toStringAsFixed(4),
        'absolute',
      ].join(' ').toNativeUtf8();
      mpv.mpv_command_string(
        ctx,
        args.cast(),
      );
      calloc.free(args);

      // It is self explanatory that PlayerState.completed & PlayerStreams.completed must enter the false state if seek is called. Typically after EOF.
      // https://github.com/alexmercerind/media_kit/issues/221
      state = state.copyWith(completed: false);
      if (!completedController.isClosed) {
        completedController.add(false);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets playlist mode.
  @override
  Future<void> setPlaylistMode(PlaylistMode playlistMode,
      {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final file = 'loop-file'.toNativeUtf8();
      final playlist = 'loop-playlist'.toNativeUtf8();
      final yes = 'yes'.toNativeUtf8();
      final no = 'no'.toNativeUtf8();
      switch (playlistMode) {
        case PlaylistMode.none:
          {
            mpv.mpv_set_property_string(
              ctx,
              file.cast(),
              no.cast(),
            );
            mpv.mpv_set_property_string(
              ctx,
              playlist.cast(),
              no.cast(),
            );
            break;
          }
        case PlaylistMode.single:
          {
            mpv.mpv_set_property_string(
              ctx,
              file.cast(),
              yes.cast(),
            );
            mpv.mpv_set_property_string(
              ctx,
              playlist.cast(),
              no.cast(),
            );
            break;
          }
        case PlaylistMode.loop:
          {
            mpv.mpv_set_property_string(
              ctx,
              file.cast(),
              no.cast(),
            );
            mpv.mpv_set_property_string(
              ctx,
              playlist.cast(),
              yes.cast(),
            );
            break;
          }
        default:
          break;
      }
      calloc.free(file);
      calloc.free(playlist);
      calloc.free(yes);
      calloc.free(no);

      state = state.copyWith(playlistMode: playlistMode);
      if (!playlistModeController.isClosed) {
        playlistModeController.add(playlistMode);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the playback volume of the [Player]. Defaults to `100.0`.
  @override
  Future<void> setVolume(double volume, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final name = 'volume'.toNativeUtf8();
      final value = calloc<Double>();
      value.value = volume;
      mpv.mpv_set_property(
        ctx,
        name.cast(),
        generated.mpv_format.MPV_FORMAT_DOUBLE,
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the playback rate of the [Player]. Defaults to `1.0`.
  @override
  Future<void> setRate(double rate, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      if (rate <= 0.0) {
        throw ArgumentError.value(
          rate,
          'rate',
          'Must be greater than 0.0',
        );
      }

      if (configuration.pitch) {
        // Pitch shift control is enabled.

        state = state.copyWith(
          rate: rate,
        );
        if (!rateController.isClosed) {
          rateController.add(state.rate);
        }
        // Apparently, using scaletempo:scale actually controls the playback rate as intended after setting audio-pitch-correction as FALSE.
        // speed on the other hand, changes the pitch when audio-pitch-correction is set to FALSE.
        // Since, it also alters the actual [speed], the scaletempo:scale is divided by the same value of [pitch] to compensate the speed change.
        var name = 'audio-pitch-correction'.toNativeUtf8();
        final no = 'no'.toNativeUtf8();
        mpv.mpv_set_property_string(
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
        mpv.mpv_set_property_string(
          ctx,
          name.cast(),
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      } else {
        // Pitch shift control is disabled.

        state = state.copyWith(
          rate: rate,
        );
        if (!rateController.isClosed) {
          rateController.add(state.rate);
        }
        final name = 'speed'.toNativeUtf8();
        final value = calloc<Double>();
        value.value = rate;
        mpv.mpv_set_property(
          ctx,
          name.cast(),
          generated.mpv_format.MPV_FORMAT_DOUBLE,
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the relative pitch of the [Player]. Defaults to `1.0`.
  @override
  Future<void> setPitch(double pitch, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      if (configuration.pitch) {
        if (pitch <= 0.0) {
          throw ArgumentError.value(
            pitch,
            'pitch',
            'Must be greater than 0.0',
          );
        }

        // Pitch shift control is enabled.

        state = state.copyWith(
          pitch: pitch,
        );
        if (!pitchController.isClosed) {
          pitchController.add(state.pitch);
        }
        // Apparently, using scaletempo:scale actually controls the playback rate as intended after setting audio-pitch-correction as FALSE.
        // speed on the other hand, changes the pitch when audio-pitch-correction is set to FALSE.
        // Since, it also alters the actual [speed], the scaletempo:scale is divided by the same value of [pitch] to compensate the speed change.
        var name = 'audio-pitch-correction'.toNativeUtf8();
        final no = 'no'.toNativeUtf8();
        mpv.mpv_set_property_string(
          ctx,
          name.cast(),
          no.cast(),
        );
        calloc.free(name);
        calloc.free(no);
        name = 'speed'.toNativeUtf8();
        final speed = calloc<Double>()..value = pitch;
        mpv.mpv_set_property(
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
        mpv.mpv_set_property_string(
          ctx,
          name.cast(),
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      } else {
        // Pitch shift control is disabled.
        throw ArgumentError('[PlayerConfiguration.pitch] is false');
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Enables or disables shuffle for [Player]. Default is `false`.
  @override
  Future<void> setShuffle(bool shuffle, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      if (shuffle == isShuffleEnabled) {
        return;
      }
      isShuffleEnabled = shuffle;

      await _command(
        [
          shuffle ? 'playlist-shuffle' : 'playlist-unshuffle',
        ],
      );
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the current [AudioDevice] for audio output.
  ///
  /// * Currently selected [AudioDevice] can be accessed using [state.audioDevice] or [stream.audioDevice].
  /// * The list of currently available [AudioDevice]s can be obtained accessed using [state.audioDevices] or [stream.audioDevices].
  @override
  Future<void> setAudioDevice(AudioDevice audioDevice,
      {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final name = 'audio-device'.toNativeUtf8();
      final value = audioDevice.name.toNativeUtf8();
      mpv.mpv_set_property_string(
        ctx,
        name.cast(),
        value.cast(),
      );
      calloc.free(name);
      calloc.free(value);
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the current [VideoTrack] for video output.
  ///
  /// * Currently selected [VideoTrack] can be accessed using [state.track.video] or [stream.track.video].
  /// * The list of currently available [VideoTrack]s can be obtained accessed using [state.tracks.video] or [stream.tracks.video].
  @override
  Future<void> setVideoTrack(VideoTrack track, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final name = 'vid'.toNativeUtf8();
      final value = track.id.toNativeUtf8();
      mpv.mpv_set_property_string(
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

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the current [AudioTrack] for audio output.
  ///
  /// * Currently selected [AudioTrack] can be accessed using [state.track.audio] or [stream.track.audio].
  /// * The list of currently available [AudioTrack]s can be obtained accessed using [state.tracks.audio] or [stream.tracks.audio].
  @override
  Future<void> setAudioTrack(AudioTrack track, {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final name = 'aid'.toNativeUtf8();
      final value = track.id.toNativeUtf8();
      mpv.mpv_set_property_string(
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

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// Sets the current [SubtitleTrack] for subtitle output.
  ///
  /// * Currently selected [SubtitleTrack] can be accessed using [state.track.subtitle] or [stream.track.subtitle].
  /// * The list of currently available [SubtitleTrack]s can be obtained accessed using [state.tracks.subtitle] or [stream.tracks.subtitle].
  @override
  Future<void> setSubtitleTrack(SubtitleTrack track,
      {bool synchronized = true}) {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      final name = 'sid'.toNativeUtf8();
      final value = track.id.toNativeUtf8();
      mpv.mpv_set_property_string(
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

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  /// [generated.mpv_handle] address of the internal libmpv player instance.
  @override
  Future<int> get handle async {
    await waitForPlayerInitialization;
    return ctx.address;
  }

  /// Sets property for the internal `libmpv` instance of this [Player].
  /// Please use this method only if you know what you are doing, existing methods in [Player] implementation are suited for the most use cases.
  ///
  /// See:
  /// * https://mpv.io/manual/master/#options
  /// * https://mpv.io/manual/master/#properties
  ///
  Future<void> setProperty(String property, String value) async {
    if (disposed) {
      throw AssertionError('[Player] has been disposed');
    }
    await waitForPlayerInitialization;
    await waitForVideoControllerInitializationIfAttached;

    final name = property.toNativeUtf8();
    final data = value.toNativeUtf8();
    mpv.mpv_set_property_string(
      ctx,
      name.cast(),
      data.cast(),
    );
    calloc.free(name);
    calloc.free(data);
  }

  Future<void> _handler(Pointer<generated.mpv_event> event) async {
    if (event.ref.event_id ==
        generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
      final prop = event.ref.data.cast<generated.mpv_event_property>();
      if (prop.ref.name.cast<Utf8>().toDartString() == 'idle-active' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        // The [Player] has entered the idle state; initialization is complete.
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      // Following properties are unrelated to the playback lifecycle. Thus, these can be accessed before initialization is complete.
      // e.g. audio-device & audio-device-list seem to be emitted before idle-active.
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
    }

    if (!completer.isCompleted) {
      // Ignore the events which are fired before the initialization.
      return;
    }

    _error(event.ref.error);

    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_START_FILE) {
      if (isPlayingStateChangeAllowed) {
        state = state.copyWith(
          playing: true,
          completed: false,
        );
        if (!playingController.isClosed) {
          playingController.add(true);
        }
        if (!completedController.isClosed) {
          completedController.add(false);
        }
      }
      state = state.copyWith(buffering: true);
      if (!bufferingController.isClosed) {
        bufferingController.add(true);
      }
    }
    // NOTE: Now, --keep-open=yes is used. Thus, eof-reached property is used instead of this.
    // if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_END_FILE) {
    //   // Check for mpv_end_file_reason.MPV_END_FILE_REASON_EOF before modifying state.completed.
    //   if (event.ref.data.cast<generated.mpv_event_end_file>().ref.reason == generated.mpv_end_file_reason.MPV_END_FILE_REASON_EOF) {
    //     if (isPlayingStateChangeAllowed) {
    //       state = state.copyWith(
    //         playing: false,
    //         completed: true,
    //       );
    //       if (!playingController.isClosed) {
    //         playingController.add(false);
    //       }
    //       if (!completedController.isClosed) {
    //         completedController.add(true);
    //       }
    //     }
    //   }
    // }
    if (event.ref.event_id ==
        generated.mpv_event_id.MPV_EVENT_PROPERTY_CHANGE) {
      final prop = event.ref.data.cast<generated.mpv_event_property>();
      if (prop.ref.name.cast<Utf8>().toDartString() == 'pause' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        final playing = prop.ref.data.cast<Int8>().value == 0;
        if (isPlayingStateChangeAllowed) {
          state = state.copyWith(playing: playing);
          if (!playingController.isClosed) {
            playingController.add(playing);
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'core-idle' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        // Check for [isBufferingStateChangeAllowed] because `pause` causes `core-idle` to be fired.
        final buffering = prop.ref.data.cast<Int8>().value == 1;
        if (isBufferingStateChangeAllowed) {
          state = state.copyWith(buffering: buffering);
          if (!bufferingController.isClosed) {
            bufferingController.add(buffering);
          }
        }
        if (buffering) {
          isBufferingStateChangeAllowed = true;
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'paused-for-cache' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        final buffering = prop.ref.data.cast<Int8>().value == 1;
        state = state.copyWith(buffering: buffering);
        if (!bufferingController.isClosed) {
          bufferingController.add(buffering);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'demuxer-cache-time' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_DOUBLE) {
        final buffer = Duration(
          microseconds: prop.ref.data.cast<Double>().value * 1e6 ~/ 1,
        );
        state = state.copyWith(buffer: buffer);
        if (!bufferController.isClosed) {
          bufferController.add(buffer);
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
        if (state.playlist.index >= 0 &&
            state.playlist.index < state.playlist.medias.length) {
          final uri = state.playlist.medias[state.playlist.index].uri;
          if (FallbackBitrateHandler.supported(uri)) {
            if (!audioBitrateCache.containsKey(Media.normalizeURI(uri))) {
              audioBitrateCache[uri] =
                  await FallbackBitrateHandler.calculateBitrate(
                uri,
                duration,
              );
            }
            final bitrate = audioBitrateCache[uri];
            if (bitrate != null) {
              state = state.copyWith(audioBitrate: bitrate);
              if (!audioBitrateController.isClosed) {
                audioBitrateController.add(bitrate);
              }
            }
          }
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'playlist' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_NODE) {
        final data = prop.ref.data.cast<generated.mpv_node>();
        final list = data.ref.u.list.ref;
        int index = -1;
        List<Media> playlist = [];
        for (int i = 0; i < list.num; i++) {
          if (list.values[i].format ==
              generated.mpv_format.MPV_FORMAT_NODE_MAP) {
            final map = list.values[i].u.list.ref;
            for (int j = 0; j < map.num; j++) {
              final property = map.keys[j].cast<Utf8>().toDartString();
              if (map.values[j].format ==
                  generated.mpv_format.MPV_FORMAT_FLAG) {
                if (property == 'playing') {
                  final value = map.values[j].u.flag;
                  if (value == 1) {
                    index = i;
                  }
                }
              }
              if (map.values[j].format ==
                  generated.mpv_format.MPV_FORMAT_STRING) {
                if (property == 'filename') {
                  final v = map.values[j].u.string.cast<Utf8>().toDartString();
                  playlist.add(Media(v));
                }
              }
            }
          }
        }
        if (index >= 0) {
          state = state.copyWith(
            playlist: Playlist(
              playlist,
              index: index,
            ),
          );
          if (!playlistController.isClosed) {
            playlistController.add(
              Playlist(
                playlist,
                index: index,
              ),
            );
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
        final list = data.ref.u.list.ref;
        final params = <String, dynamic>{};
        for (int i = 0; i < list.num; i++) {
          final key = list.keys[i].cast<Utf8>().toDartString();

          switch (key) {
            case 'format':
              {
                params[key] =
                    list.values[i].u.string.cast<Utf8>().toDartString();
                break;
              }
            case 'samplerate':
              {
                params[key] = list.values[i].u.int64;
                break;
              }
            case 'channels':
              {
                params[key] =
                    list.values[i].u.string.cast<Utf8>().toDartString();
                break;
              }
            case 'channel-count':
              {
                params[key] = list.values[i].u.int64;
                break;
              }
            case 'hr-channels':
              {
                params[key] =
                    list.values[i].u.string.cast<Utf8>().toDartString();
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
          if (!FallbackBitrateHandler.supported(uri)) {
            if (!audioBitrateCache.containsKey(Media.normalizeURI(uri))) {
              audioBitrateCache[Media.normalizeURI(uri)] = data;
            }
            final bitrate = audioBitrateCache[Media.normalizeURI(uri)];
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
      if (prop.ref.name.cast<Utf8>().toDartString() == 'width' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
        final width = prop.ref.data.cast<Int64>().value;
        state = state.copyWith(width: width);
        if (!widthController.isClosed) {
          widthController.add(width);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'height' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_INT64) {
        final height = prop.ref.data.cast<Int64>().value;
        state = state.copyWith(height: height);
        if (!heightController.isClosed) {
          heightController.add(height);
        }
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'eof-reached' &&
          prop.ref.format == generated.mpv_format.MPV_FORMAT_FLAG) {
        final value = prop.ref.data.cast<Bool>().value;
        if (value) {
          if (isPlayingStateChangeAllowed) {
            state = state.copyWith(
              playing: false,
              completed: true,
            );
            if (!playingController.isClosed) {
              playingController.add(false);
            }
            if (!completedController.isClosed) {
              completedController.add(true);
            }
          }
          state = state.copyWith(buffering: false);
          if (!bufferingController.isClosed) {
            bufferingController.add(false);
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
        // --------------------------------------------------
        // Emit error(s) based on the log messages.
        if (level == 'error') {
          if (prefix == 'file') {
            // file:// not found.
            if (!errorController.isClosed) {
              errorController.add(text);
            }
          }
        }
        if (level == 'error') {
          if (prefix == 'ffmpeg') {
            if (text.startsWith('tcp:')) {
              // http:// error of any kind.
              if (!errorController.isClosed) {
                errorController.add(text);
              }
            }
          }
        }
        // --------------------------------------------------
      }
    }
    // Handle HTTP headers specified in the [Media].
    if (event.ref.event_id == generated.mpv_event_id.MPV_EVENT_HOOK) {
      final prop = event.ref.data.cast<generated.mpv_event_hook>();
      if (prop.ref.name.cast<Utf8>().toDartString() == 'on_load') {
        try {
          final name = 'path'.toNativeUtf8();
          final uri = mpv.mpv_get_property_string(
            ctx,
            name.cast(),
          );
          // Get the headers for current [Media] by looking up [uri] in the [HashMap].
          final headers = Media(uri.cast<Utf8>().toDartString()).httpHeaders;
          if (headers != null) {
            final property = 'http-header-fields'.toNativeUtf8();
            // Allocate & fill the [mpv_node] with the headers.
            final value = calloc<generated.mpv_node>();
            value.ref.format = generated.mpv_format.MPV_FORMAT_NODE_ARRAY;
            value.ref.u.list = calloc<generated.mpv_node_list>();
            value.ref.u.list.ref.num = headers.length;
            value.ref.u.list.ref.values = calloc<generated.mpv_node>(
              headers.length,
            );
            final entries = headers.entries.toList();
            for (int i = 0; i < entries.length; i++) {
              final k = entries[i].key;
              final v = entries[i].value;
              final data = '$k: $v'.toNativeUtf8();
              value.ref.u.list.ref.values[i].format =
                  generated.mpv_format.MPV_FORMAT_STRING;
              value.ref.u.list.ref.values[i].u.string = data.cast();
            }
            mpv.mpv_set_property(
              ctx,
              property.cast(),
              generated.mpv_format.MPV_FORMAT_NODE,
              value.cast(),
            );
            // Free the allocated memory.
            calloc.free(property);
            for (int i = 0; i < value.ref.u.list.ref.num; i++) {
              calloc.free(value.ref.u.list.ref.values[i].u.string);
            }
            calloc.free(value.ref.u.list.ref.values);
            calloc.free(value.ref.u.list);
            calloc.free(value);
          }
          mpv.mpv_free(uri.cast());
          calloc.free(name);
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
        mpv.mpv_hook_continue(
          ctx,
          prop.ref.id,
        );
      }
      if (prop.ref.name.cast<Utf8>().toDartString() == 'on_unload') {
        try {
          // Set http-header-fields as empty [generated.mpv_node].
          final property = 'http-header-fields'.toNativeUtf8();
          final value = calloc<generated.mpv_node>();
          mpv.mpv_set_property(
            ctx,
            property.cast(),
            generated.mpv_format.MPV_FORMAT_NODE,
            value.cast(),
          );
          calloc.free(property);
          calloc.free(value);
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
        mpv.mpv_hook_continue(
          ctx,
          prop.ref.id,
        );
      }
    }
  }

  Future<void> _create() {
    return lock.synchronized(() async {
      // The libmpv options which must be set before [MPV.mpv_initialize].
      final options = <String, String>{};

      if (Platform.isAndroid) {
        try {
          // On Android, the system fonts cannot be picked up by libass/fontconfig. This makes subtitles not work.
          // We manually save `subfont.ttf` to the application's cache directory and set `config` & `config-dir` to use it.
          final subfont = await AndroidAssetLoader.load('subfont.ttf');
          if (subfont.isNotEmpty) {
            final directory = dirname(subfont);
            // This asset is bundled as part of `package:media_kit_libs_android_video`.
            // Use it if located inside the application bundle, otherwise no worries.
            options.addAll(
              {
                'config': 'yes',
                'config-dir': directory,
              },
            );
            print(subfont);
            print(directory);
          }
        } catch (exception, stacktrace) {
          print(exception);
          print(stacktrace);
        }
      }

      ctx = await Initializer.create(
        NativeLibrary.path,
        _handler,
        options: options,
      );

      // ALL:
      //
      // idle = yes
      // pause = yes
      // keep-open = yes
      // network-timeout = 5
      // demuxer-max-bytes = 32 * 1024 * 1024
      // demuxer-max-back-bytes = 32 * 1024 * 1024
      //
      // ANDROID (Physical Device OR API Level > 25):
      //
      // ao = opensles
      //
      // ANDROID (Emulator AND API Level <= 25):
      //
      // ao = null
      //
      final properties = <String, String>{
        'idle': 'yes',
        'pause': 'yes',
        'keep-open': 'yes',
        'network-timeout': '5',
        'demuxer-max-bytes': (32 * 1024 * 1024).toString(),
        'demuxer-max-back-bytes': (32 * 1024 * 1024).toString(),
        // On Android, prefer OpenSL ES audio output.
        // AudioTrack audio output is prone to crashes in some rare cases.
        if (AndroidHelper.isPhysicalDevice || AndroidHelper.APILevel > 25)
          'ao': 'opensles'
        // Disable audio output on older Android emulators with API Level < 25.
        // OpenSL ES audio output seems to be broken on some of these.
        else if (AndroidHelper.isEmulator && AndroidHelper.APILevel <= 25)
          'ao': 'null',
      };
      // Other properties based on [PlayerConfiguration].
      properties.addAll(
        {
          if (!configuration.osc) ...{
            'osc': 'no',
            'osd-level': '0',
          },
          if (configuration.vo != null) 'vo': '${configuration.vo}',
          if (configuration.title != null) 'title': '${configuration.title}',
          'demuxer-lavf-o':
              'protocol_whitelist=[${configuration.protocolWhitelist.join(',')}]',
        },
      );
      for (final property in properties.entries) {
        final name = property.key.toNativeUtf8();
        final value = property.value.toNativeUtf8();
        mpv.mpv_set_property_string(
          ctx,
          name.cast(),
          value.cast(),
        );
        calloc.free(name);
        calloc.free(value);
      }

      // Observe the properties to update the state & feed event stream.
      <String, int>{
        'pause': generated.mpv_format.MPV_FORMAT_FLAG,
        'time-pos': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'duration': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'playlist': generated.mpv_format.MPV_FORMAT_NODE,
        'volume': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'speed': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'core-idle': generated.mpv_format.MPV_FORMAT_FLAG,
        'paused-for-cache': generated.mpv_format.MPV_FORMAT_FLAG,
        'demuxer-cache-time': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'audio-params': generated.mpv_format.MPV_FORMAT_NODE,
        'audio-bitrate': generated.mpv_format.MPV_FORMAT_DOUBLE,
        'audio-device': generated.mpv_format.MPV_FORMAT_NODE,
        'audio-device-list': generated.mpv_format.MPV_FORMAT_NODE,
        'track-list': generated.mpv_format.MPV_FORMAT_NODE,
        'width': generated.mpv_format.MPV_FORMAT_INT64,
        'height': generated.mpv_format.MPV_FORMAT_INT64,
        'eof-reached': generated.mpv_format.MPV_FORMAT_FLAG,
        'idle-active': generated.mpv_format.MPV_FORMAT_FLAG,
      }.forEach(
        (property, format) {
          final name = property.toNativeUtf8();
          mpv.mpv_observe_property(
            ctx,
            0,
            name.cast(),
            format,
          );
          calloc.free(name);
        },
      );

      // https://github.com/mpv-player/mpv/blob/e1727553f164181265f71a20106fbd5e34fa08b0/libmpv/client.h#L1410-L1419
      final levels = {
        MPVLogLevel.error: 'error',
        MPVLogLevel.warn: 'warn',
        MPVLogLevel.info: 'info',
        MPVLogLevel.v: 'v',
        MPVLogLevel.debug: 'debug',
        MPVLogLevel.trace: 'trace',
      };
      final level = levels[configuration.logLevel];
      if (level != null) {
        final min = level.toNativeUtf8();
        mpv.mpv_request_log_messages(ctx, min.cast());
        calloc.free(min);
      }

      // Add libmpv hooks for supporting custom HTTP headers in [Media].
      final load = 'on_load'.toNativeUtf8();
      final unload = 'on_unload'.toNativeUtf8();
      mpv.mpv_hook_add(ctx, 0, load.cast(), 0);
      mpv.mpv_hook_add(ctx, 0, unload.cast(), 0);
      calloc.free(load);
      calloc.free(unload);
    });
  }

  /// Adds an error to the [Player.stream.error].
  void _error(int code) {
    if (code < 0 && !errorController.isClosed) {
      final message = mpv.mpv_error_string(code).cast<Utf8>().toDartString();
      errorController.add(message);
    }
  }

  /// Calls mpv command passed as [args]. Automatically freeds memory after command sending.
  Future<void> _command(List<String?> args) async {
    final List<Pointer<Utf8>> pointers = args.map<Pointer<Utf8>>((e) {
      if (e == null) return nullptr.cast();
      return e.toNativeUtf8();
    }).toList();
    final Pointer<Pointer<Utf8>> arr = calloc.allocate(args.join().length);
    for (int i = 0; i < args.length; i++) {
      arr[i] = pointers[i];
    }
    mpv.mpv_command(
      ctx,
      arr.cast(),
    );
    calloc.free(arr);
    pointers.forEach(calloc.free);
  }

  /// Internal generated libmpv C API bindings.
  final generated.MPV mpv;

  /// [Pointer] to [generated.mpv_handle] of this instance.
  Pointer<generated.mpv_handle> ctx = nullptr;

  /// Whether the [Player] has been disposed. This is used to prevent accessing dangling [ctx] after [dispose].
  bool disposed = false;

  /// A flag to keep track of [setShuffle] calls.
  bool isShuffleEnabled = false;

  /// A flag to prevent changes to [state.playing] due to `loadfile` commands in [open].
  ///
  /// By default, `MPV_EVENT_START_FILE` is fired when a new media source is loaded.
  /// This event modifies the [state.playing] & [stream.playing] to `true`.
  ///
  /// However, the [Player] is in paused state before the media source is loaded.
  /// Thus, [state.playing] should not be changed, unless the user explicitly calls [play] or [playOrPause].
  ///
  /// We set [isPlayingStateChangeAllowed] to `false` at the start of [open] to prevent this unwanted change & set it to `true` at the end of [open].
  /// While [isPlayingStateChangeAllowed] is `false`, any change to [state.playing] & [stream.playing] is ignored.
  bool isPlayingStateChangeAllowed = false;

  /// A flag to prevent changes to [state.buffering] due to `pause` causing `core-idle` to be `true`.
  ///
  /// This is used to prevent [state.buffering] being set to `true` when [pause] or [playOrPause] is called.
  bool isBufferingStateChangeAllowed = true;

  /// [Completer] to wait for initialization of this instance (in [_create]).
  final Completer<void> completer = Completer<void>();

  /// [Future<void>] to wait for initialization of this instance.
  Future<void> get waitForPlayerInitialization => completer.future;

  /// Synchronization & mutual exclusion between methods of this class.
  static final LockExt lock = LockExt();

  /// [HashMap] for retrieving previously fetched audio-bitrate(s).
  static final HashMap<String, double> audioBitrateCache =
      HashMap<String, double>();

  /// Whether `mpv_terminate_destroy` should be called in [dispose].
  @visibleForTesting
  static bool terminate = true;
}
