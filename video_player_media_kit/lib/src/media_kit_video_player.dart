/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

// https://github.com/dart-lang/linter/issues/1381
// ignore_for_file: close_sinks

/// package:media_kit implementation of [VideoPlayerPlatform].
///
/// References:
/// * https://pub.dev/packages/media_kit
/// * https://github.com/media-kit/media-kit
///
class MediaKitVideoPlayer extends VideoPlayerPlatform {
  // The implementation uses [Player.hashCode] as texture ID.
  final _players = HashMap<int, Player>();
  final _completers = HashMap<int, Completer<void>>();
  final _videoControllers = HashMap<int, VideoController>();
  final _streamControllers = HashMap<int, StreamController<VideoEvent>>();
  final _streamSubscriptions = HashMap<int, List<StreamSubscription>>();

  /// Registers this class as the default instance of [VideoPlayerPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = MediaKitVideoPlayer();
  }

  /// Initializes the platform interface and disposes all existing players.
  ///
  /// This method is called when the plugin is first initialized and on every full restart.
  @override
  Future<void> init() async {
    for (final textureId in _players.keys) {
      await dispose(textureId);
    }

    _players.clear();
    _videoControllers.clear();
    _streamControllers.clear();
    _streamSubscriptions.clear();
  }

  /// Clears one video.
  @override
  Future<void> dispose(int textureId) async {
    await _players[textureId]?.dispose();

    await _streamControllers[textureId]?.close();
    await Future.wait(
      _streamSubscriptions[textureId]?.map((e) => e.cancel()) ?? [],
    );

    _players.remove(textureId);
    _videoControllers.remove(textureId);
    _streamControllers.remove(textureId);
    _streamSubscriptions.remove(textureId);
  }

  /// Creates an instance of a video player and returns its textureId.
  @override
  Future<int?> create(DataSource dataSource) async {
    final player = Player();
    final completer = Completer();
    final videoController = VideoController(player);
    // NOTE: [StreamController] without broadcast buffers events.
    final streamController = StreamController<VideoEvent>();
    final streamSubscriptions = <StreamSubscription>[];

    final textureId = player.hashCode;

    _players[textureId] = player;
    _completers[textureId] = completer;
    _videoControllers[textureId] = videoController;
    _streamControllers[textureId] = streamController;
    _streamSubscriptions[textureId] = streamSubscriptions;

    // --------------------------------------------------
    _initialize(textureId);
    // --------------------------------------------------

    final String resource;
    final Map<String, String> httpHeaders = dataSource.httpHeaders;

    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        final String? asset;
        if (dataSource.package == null) {
          asset = dataSource.asset;
        } else {
          asset = 'packages/${dataSource.package}/${dataSource.asset}';
        }
        resource = 'asset:///$asset';
        break;

      case DataSourceType.network:
      case DataSourceType.file:
      case DataSourceType.contentUri:
        if (dataSource.uri == null) {
          throw ArgumentError('uri must not be null');
        }
        resource = dataSource.uri!;
        break;

      default:
        throw UnsupportedError('${dataSource.sourceType} is not supported');
    }

    await player.open(
      Media(
        resource,
        httpHeaders: httpHeaders,
      ),
      play: false,
    );

    return textureId;
  }

  /// Returns a Stream of [VideoEventType]s.
  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    if (_streamControllers[textureId] == null) {
      throw StateError(
          'VideoPlayer for textureId $textureId is not found, Check if its disposed.');
    }
    return _streamControllers[textureId]!.stream;
  }

  /// Sets the looping attribute of the video.
  @override
  Future<void> setLooping(int textureId, bool looping) async {
    final playlistMode = looping ? PlaylistMode.single : PlaylistMode.none;
    return _players[textureId]?.setPlaylistMode(playlistMode);
  }

  /// Starts the video playback.
  @override
  Future<void> play(int textureId) async {
    return _players[textureId]?.play();
  }

  /// Stops the video playback.
  @override
  Future<void> pause(int textureId) async {
    return _players[textureId]?.pause();
  }

  /// Sets the volume to a range between 0.0 and 1.0.
  @override
  Future<void> setVolume(int textureId, double volume) async {
    // NOTE: [volume] is in the range of 0.0 to 1.0 while [setVolume] expects 0.0 to 100.
    return _players[textureId]?.setVolume(volume * 100);
  }

  /// Sets the video position to a [Duration] from the start.
  @override
  Future<void> seekTo(int textureId, Duration position) async {
    return _players[textureId]?.seek(position);
  }

  /// Sets the playback speed to a [speed] value indicating the playback rate.
  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    return _players[textureId]?.setRate(speed);
  }

  /// Gets the video position as [Duration] from the start.
  @override
  Future<Duration> getPosition(int textureId) async {
    return _players[textureId]?.platform?.state.position ?? Duration.zero;
  }

  /// Returns a widget displaying the video with a given textureId.
  @override
  Widget buildView(int textureId) {
    if (_videoControllers[textureId] == null) {
      throw StateError(
          'VideoPlayer for textureId $textureId is not found, Check if its disposed.');
    }
    return Video(
      key: ValueKey(_videoControllers[textureId]!),
      controller: _videoControllers[textureId]!,
      wakelock: false,
      controls: NoVideoControls,
      fill: const Color(0x00000000),
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    );
  }

  /// Sets the audio mode to mix with other sources.
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) => Future.value();

  /// Sets additional options on web.
  @override
  Future<void> setWebOptions(int textureId, VideoPlayerWebOptions options) =>
      Future.value();

  /// Initialize the [Stream]s for a given textureId.
  void _initialize(int textureId) {
    if (_streamSubscriptions[textureId]?.isNotEmpty ?? false) {
      return;
    }

    final player = _players[textureId];
    final completer = _completers[textureId];
    final streamController = _streamControllers[textureId];
    final streamSubscriptions = _streamSubscriptions[textureId];

    if (player != null &&
        completer != null &&
        streamController != null &&
        streamSubscriptions != null) {
      // VideoEventType.initialized

      int? width;
      int? height;
      Duration? duration;

      void notify() {
        if (!completer.isCompleted) {
          if (width != null && height != null && duration != null) {
            streamController.add(
              VideoEvent(
                eventType: VideoEventType.initialized,
                size: Size(
                  (width ?? 0) * 1.0,
                  (height ?? 0) * 1.0,
                ),
                duration: player.state.duration,
              ),
            );
            completer.complete();
          }
        }
      }

      streamSubscriptions.add(
        player.stream.duration.listen(
          (event) {
            if (event > Duration.zero) {
              duration = event;
              notify();
            }
          },
        ),
      );
      streamSubscriptions.add(
        player.stream.videoParams.listen(
          (event) {
            width = event.dw;
            height = event.dh;
            if ((width ?? 0) > 0 && (height ?? 0) > 0) {
              notify();
            }
          },
        ),
      );
      streamSubscriptions.add(
        player.stream.tracks.listen(
          (event) {
            // No video track is available i.e. an audio file.
            if (event.video.length == 2 && event.audio.length > 2) {
              width = 0;
              height = 0;
              notify();
            }
          },
        ),
      );
      // VideoEventType.isPlayingStateUpdate
      streamSubscriptions.add(
        player.stream.playing.listen(
          (event) async {
            await completer.future;
            streamController.add(
              VideoEvent(
                eventType: VideoEventType.isPlayingStateUpdate,
                isPlaying: event,
              ),
            );
          },
        ),
      );
      // VideoEventType.completed
      streamSubscriptions.add(
        player.stream.completed.listen(
          (event) async {
            await completer.future;
            if (event) {
              streamController.add(
                VideoEvent(
                  eventType: VideoEventType.completed,
                ),
              );
            }
          },
        ),
      );
      // VideoEventType.bufferingStart
      streamSubscriptions.add(
        player.stream.buffering.listen(
          (event) async {
            await completer.future;
            streamController.add(
              VideoEvent(
                eventType: event
                    ? VideoEventType.bufferingStart
                    : VideoEventType.bufferingEnd,
              ),
            );
          },
        ),
      );
      // VideoEventType.bufferingUpdate
      streamSubscriptions.add(
        player.stream.buffer.listen(
          (event) async {
            await completer.future;
            streamController.add(
              VideoEvent(
                eventType: VideoEventType.bufferingUpdate,
                buffered: [
                  DurationRange(
                    Duration.zero,
                    event,
                  ),
                ],
              ),
            );
          },
        ),
      );

      streamSubscriptions.add(
        player.stream.error.listen(
          (event) async {
            await completer.future;
            streamController.addError(
              PlatformException(
                code: '',
                message: event,
              ),
            );
          },
        ),
      );
    }
  }
}
