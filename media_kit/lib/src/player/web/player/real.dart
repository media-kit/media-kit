/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: camel_case_types
import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:synchronized/synchronized.dart';

import 'package:media_kit/src/player/platform_player.dart';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

/// Initializes the web backend for package:media_kit.
void webEnsureInitialized({String? libmpv}) {}

/// {@template web_player}
///
/// webPlayer
/// ---------
///
/// HTML `<video>` based implementation of [PlatformPlayer].
///
/// {@endtemplate}
class webPlayer extends PlatformPlayer {
  /// {@macro web_player}
  webPlayer({required super.configuration})
      : id = js.context[kInstanceCount] ?? 0,
        element = html.VideoElement() {
    lock.synchronized(() async {
      element
        // Do not add autoplay=false attribute: https://stackoverflow.com/a/19664804/12825435
        /* ..autoplay = false */
        ..controls = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        /* ..setAttribute('autoplay', 'false') */
        ..setAttribute('playsinline', 'true')
        ..pause();
      // Initialize or increment the instance count.
      js.context[kInstanceCount] ??= 0;
      js.context[kInstanceCount]++;
      // Store the [html.VideoElement] instance in global [js.context].
      js.context[kInstances] ??= js.JsObject.jsify({});
      js.context[kInstances][id] = element;
      // --------------------------------------------------
      // Event streams handling:
      element.onPlay.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.playing & PlayerState.stream.playing
          state = state.copyWith(playing: true);
          if (!playingController.isClosed) {
            playingController.add(true);
          }
        });
      });
      element.onPause.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.playing & PlayerState.stream.playing
          state = state.copyWith(playing: false);
          if (!playingController.isClosed) {
            playingController.add(false);
          }
        });
      });
      element.onPlaying.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.playing & PlayerState.stream.playing
          // PlayerState.state.buffering & PlayerState.stream.buffering
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
        });
      });
      element.onEnded.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.playing & PlayerState.stream.playing
          // PlayerState.state.completed & PlayerState.stream.completed
          // PlayerState.state.buffering & PlayerState.stream.buffering
          state = state.copyWith(
            playing: false,
            completed: true,
            buffering: false,
          );
          if (!playingController.isClosed) {
            playingController.add(false);
          }
          if (!completedController.isClosed) {
            completedController.add(true);
          }
          if (!bufferingController.isClosed) {
            bufferingController.add(false);
          }
          // PlayerState.state.playlist.index & PlayerState.stream.playlist.index
          if (Media.normalizeURI(element.src) == _playlist[_index].uri) {
            switch (_playlistMode) {
              case PlaylistMode.none:
                {
                  if (_index < _playlist.length - 1) {
                    _index = _index + 1;
                    final current = _playlist[_index];
                    element.src = current.uri;
                    element.play();
                  } else {
                    // Playback must end.
                  }
                  break;
                }
              case PlaylistMode.single:
                {
                  final current = _playlist[_index];
                  element.src = current.uri;
                  element.play();
                  break;
                }
              case PlaylistMode.loop:
                {
                  _index = (_index + 1) % _playlist.length;
                  final current = _playlist[_index];
                  element.src = current.uri;
                  element.play();
                  break;
                }
            }
            // Update:
            state = state.copyWith(
              playlist: state.playlist.copyWith(
                index: _index,
              ),
            );
            if (!playlistController.isClosed) {
              playlistController.add(state.playlist);
            }
          }
        });
      });
      element.onTimeUpdate.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.position & PlayerState.stream.position
          final value = element.currentTime * 1000 ~/ 1;
          final position = Duration(milliseconds: value);
          state = state.copyWith(position: position);
          if (!positionController.isClosed) {
            positionController.add(position);
          }
          // PlayerState.state.buffer & PlayerState.stream.buffer
          final i = element.buffered.length - 1;
          if (i >= 0) {
            final value = element.buffered.end(i) * 1000 ~/ 1;
            final buffer = Duration(milliseconds: value);
            if (!bufferController.isClosed) {
              bufferController.add(buffer);
            }
          }
        });
      });
      element.onDurationChange.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.duration & PlayerState.stream.duration
          final value = element.duration * 1000 ~/ 1;
          final duration = Duration(milliseconds: value);
          state = state.copyWith(duration: duration);
          if (!durationController.isClosed) {
            durationController.add(duration);
          }
        });
      });
      element.onWaiting.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.buffering & PlayerState.stream.buffering
          state = state.copyWith(buffering: true);
          if (!bufferingController.isClosed) {
            bufferingController.add(true);
          }
          // PlayerState.state.buffer & PlayerState.stream.buffer
          final i = element.buffered.length - 1;
          if (i >= 0) {
            final value = element.buffered.end(i) * 1000 ~/ 1;
            final buffer = Duration(milliseconds: value);
            if (!bufferController.isClosed) {
              bufferController.add(buffer);
            }
          }
        });
      });
      element.onCanPlay.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.buffering & PlayerState.stream.buffering
          state = state.copyWith(buffering: false);
          if (!bufferingController.isClosed) {
            bufferingController.add(false);
          }
        });
      });
      element.onCanPlayThrough.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.buffering & PlayerState.stream.buffering
          state = state.copyWith(buffering: false);
          if (!bufferingController.isClosed) {
            bufferingController.add(false);
          }
        });
      });
      element.onVolumeChange.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.volume & PlayerState.stream.volume
          final volume = element.volume * 100.0;
          state = state.copyWith(volume: volume);
          if (!volumeController.isClosed) {
            volumeController.add(volume);
          }
        });
      });
      element.onRateChange.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.speed & PlayerState.stream.speed
          final rate = element.playbackRate * 1.0;
          state = state.copyWith(rate: rate);
          if (!rateController.isClosed) {
            rateController.add(rate);
          }
        });
      });
      element.onError.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.buffering & PlayerState.stream.buffering
          state = state.copyWith(buffering: false);
          if (!bufferingController.isClosed) {
            bufferingController.add(false);
          }
          // PlayerStream.error
          final error = element.error!;
          if (!errorController.isClosed) {
            errorController.addError(error.message ?? '');
          }
        });
      });
      element.onResize.listen((_) {
        lock.synchronized(() async {
          // PlayerState.state.width & PlayerState.stream.width
          // PlayerState.state.height & PlayerState.stream.height
          final width = element.videoWidth;
          final height = element.videoHeight;
          state = state.copyWith(
            width: width,
            height: height,
          );
          if (!widthController.isClosed) {
            widthController.add(width);
          }
          if (!heightController.isClosed) {
            heightController.add(height);
          }
        });
      });
      // --------------------------------------------------
    });
  }

  @override
  Future<void> dispose({bool synchronized = true}) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      disposed = true;

      element
        ..src = ''
        ..load()
        ..remove();

      // Remove the [html.VideoElement] instance from global [js.context].
      js.context[kInstances].deleteProperty(id);

      await super.dispose();
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
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

      state = state.copyWith(playing: false);
      if (!playingController.isClosed) {
        playingController.add(false);
      }

      _index = index;
      _playlist = playlist;

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

      try {
        element.src = _playlist[_index].uri;
      } catch (exception) {
        // PlayerStream.error
        final e = exception as html.DomException;
        if (!errorController.isClosed) {
          errorController.add(e.message ?? '');
        }
      }

      if (play) {
        await element.play();
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> play({bool synchronized = true}) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      try {
        await element.play();
      } catch (exception) {
        // PlayerStream.error
        final e = exception as html.DomException;
        if (!errorController.isClosed) {
          errorController.add(e.message ?? '');
        }
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> pause({bool synchronized = true}) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      element.pause();
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> playOrPause({bool synchronized = true}) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      if (element.paused) {
        await play(synchronized: false);
      } else {
        await pause(synchronized: false);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> add(
    Media media, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> remove(
    int index, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> next({
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      Future<void> start() async {
        state = state.copyWith(
          playlist: state.playlist.copyWith(
            index: _index,
          ),
        );

        element.src = _playlist[_index].uri;
        await play(synchronized: false);

        state = state.copyWith(playing: true);
        if (!playingController.isClosed) {
          playingController.add(true);
        }
      }

      switch (_playlistMode) {
        case PlaylistMode.none:
          {
            if (_index < _playlist.length - 1) {
              _index++;
              await start();
            } else {
              // No transition.
            }
            break;
          }
        case PlaylistMode.single:
          {
            if (_index < _playlist.length - 1) {
              _index++;
              await start();
            } else {
              // No transition.
            }
            break;
          }
        case PlaylistMode.loop:
          {
            _index = (_index + 1) % _playlist.length;
            await start();
            break;
          }
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> previous({
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      Future<void> start() async {
        state = state.copyWith(
          playlist: state.playlist.copyWith(
            index: _index,
          ),
        );

        element.src = _playlist[_index].uri;
        await play(synchronized: false);

        state = state.copyWith(playing: true);
        if (!playingController.isClosed) {
          playingController.add(true);
        }
      }

      switch (_playlistMode) {
        case PlaylistMode.none:
          {
            if (_index > 0) {
              _index--;
              await start();
            } else {
              // No transition.
            }
            break;
          }
        case PlaylistMode.single:
          {
            if (_index > 0) {
              _index--;
              await start();
            } else {
              // No transition.
            }
            break;
          }
        case PlaylistMode.loop:
          {
            _index = (_index - 1) % _playlist.length;
            await start();
            break;
          }
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> jump(
    int index, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;

      _index = index;

      element.src = _playlist[_index].uri;
      await element.play();

      state = state.copyWith(playing: true);
      if (!playingController.isClosed) {
        playingController.add(true);
      }
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> move(
    int from,
    int to, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> seek(
    Duration duration, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      element.currentTime = duration.inMilliseconds.toDouble() / 1000;
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setPlaylistMode(
    PlaylistMode playlistMode, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      _playlistMode = playlistMode;
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setVolume(
    double volume, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      element.volume = volume / 100.0;
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setRate(
    double rate, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      element.playbackRate = rate;
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setPitch(
    double pitch, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      throw UnsupportedError('[Player.setPitch] is not supported on web');
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setShuffle(
    bool shuffle, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      _shuffle = shuffle;
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setAudioDevice(
    AudioDevice audioDevice, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      throw UnsupportedError('[Player.setAudioDevice] is not supported on web');
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setVideoTrack(
    VideoTrack track, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setAudioTrack(
    AudioTrack track, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  @override
  Future<void> setSubtitleTrack(
    SubtitleTrack track, {
    bool synchronized = true,
  }) async {
    Future<void> function() async {
      if (disposed) {
        throw AssertionError('[Player] has been disposed');
      }
      await waitForPlayerInitialization;
      await waitForVideoControllerInitializationIfAttached;
      // TODO: Missing implementation.
    }

    if (synchronized) {
      return lock.synchronized(function);
    } else {
      return function();
    }
  }

  // --------------------------------------------------

  /// Whether shuffle is enabled.
  bool _shuffle = false;

  /// Current index of the [Media] in the queue.
  int _index = 0;

  /// Current loaded [Media]s queue.
  List<Media> _playlist = <Media>[];

  /// Current playlist mode.
  PlaylistMode _playlistMode = PlaylistMode.none;

  // --------------------------------------------------

  @override
  Future<int> get handle => Future.value(id);

  /// Unique handle of this [Player] instance.
  final int id;

  /// [html.VideoElement] instance reference.
  final html.VideoElement element;

  /// Whether the [Player] has been disposed.
  bool disposed = false;

  /// [Future<void>] to wait for initialization of this instance.
  Future<void> get waitForPlayerInitialization =>
      Future.value() /* Not required. */;

  /// Synchronization & mutual exclusion between methods of this class.
  final Lock lock = Lock();

  /// JavaScript object attribute used to store various [VideoElement] instances in [js.context].
  static const kInstances = '\$com.alexmercerind.media_kit.instances';

  /// JavaScript object attribute used to store the instance count of [Player] in [js.context].
  static const kInstanceCount = '\$com.alexmercerind.media_kit.instance_count';
}
