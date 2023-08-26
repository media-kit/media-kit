import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player_media_kit/video_player_media_kit_interface/media_kit_theme.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class VideoPlayerMediaKitWidget extends StatelessWidget {
  final VideoController controller;
  const VideoPlayerMediaKitWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = MediaKitTheme.maybeOf(context);
    if (theme != null) {
      return Video(
        controller: controller,
        wakelock: false,
        controls: NoVideoControls,
        fill: theme.fillColor,

        // height: 1920.0,
        // width: 1080.0,
        // scale: 1.0, // default
        // showControls: false,
      );
    }
    return Video(
      controller: controller,
      wakelock: false,
      controls: NoVideoControls,

      // height: 1920.0,
      // width: 1080.0,
      // scale: 1.0, // default
      // showControls: false,
    );
  }
}

class VideoPlayerMediaKit extends VideoPlayerPlatform {
  VideoPlayerMediaKit(
      {this.logLevel = MPVLogLevel.warn, this.throwErrors = true});

  MPVLogLevel logLevel;

  /// throw playback errors
  bool throwErrors;

  ///`players`: A map that stores the initialized video players. The keys of the map are unique integers assigned to each player, and the values are instances of the Player class.
  Map<int, Player> players = {};

  ///`controllers`: A map that stores the video controllers for each player. The keys are unique integers assigned to each player, and the values are instances of the VideoController class.
  Map<int, VideoController> controllers = {};

  ///`durations`: A map that stores the duration of each video in microseconds for which the player is initialized. The keys are unique integers assigned to each player.
  ///used to know when player is initialized
  Map<int, int> durations = {};

  /// `isLive`: A map that stores the live status of each video for which the player is initialized.
  /// The keys are unique integers assigned to each player. A value of `true` indicates that the video is live,
  /// while `false` indicates that it is not. This map is used to track when a player is initialized and whether
  /// the associated video is live or not.
  Map<int, bool> isLive = {};

  ///`counter`: An integer that is used to assign unique IDs to each player instance. The IDs are used as keys in the players, and controllers maps.
  int counter = 0;

  ///`streams`: A map that stores the streams controllers for each player.
  Map<int, StreamController<VideoEvent>> streams = {};

  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith(
      {MPVLogLevel logLevel = MPVLogLevel.error, bool throwErrors = true}) {
    VideoPlayerPlatform.instance =
        VideoPlayerMediaKit(logLevel: logLevel, throwErrors: throwErrors);

    return;
  }

  void _disposeAllPlayers() {
    for (final int videoPlayerId in players.keys) {
      dispose(videoPlayerId);
    }
    players.clear();
  }

  @override
  Widget buildView(int textureId) {
    // print(controllers[textureId]);

    return VideoPlayerMediaKitWidget(
      controller: controllers[textureId]!,
    );
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    Player player = Player(
        configuration: PlayerConfiguration(
            logLevel: logLevel)); // create a new video controller

    int id = counter++;
    // print(id);
    players[id] = player;
    initStreams(id);
    controllers[id] = VideoController(player);
    player.setPlaylistMode(PlaylistMode.loop);

    // int id = await player.handle;
    // playersHandles[counter] = id;

    // print(dataSource.asset);
    // print(dataSource.uri);
    if (dataSource.sourceType == DataSourceType.asset) {
      final assetName = dataSource.asset!;
      final assetUrl =
          assetName.startsWith("asset://") ? assetName : "asset://$assetName";
      player.open(
        Media(assetUrl, httpHeaders: dataSource.httpHeaders), play: false,

        // autoStart: _autoplay,
      );
    } else if (dataSource.sourceType == DataSourceType.network) {
      player.open(Media(dataSource.uri!, httpHeaders: dataSource.httpHeaders),
          play: false);
    } else {
      if (!await File.fromUri(Uri.parse(dataSource.uri!)).exists()) {
        throw Exception("${dataSource.uri!} not found ");
      }
      player.open(Media(dataSource.uri!, httpHeaders: dataSource.httpHeaders),
          play: false
          // autoStart: _autoplay,
          );
    }
    return id;
  }

  void initStreams(int textureId) {
    streams[textureId] = StreamController<VideoEvent>();
    players[textureId]!.stream.completed.listen((event) {
      if (event) {
        players[textureId]!.platform!.state = players[textureId]!
            .platform!
            .state
            .copyWith(position: players[textureId]!.platform!.state.duration);
        streams[textureId]!.add(VideoEvent(
          eventType: VideoEventType.completed,
        ));
      }
    });
    players[textureId]!.stream.log.listen((event) {
      final logEntry = {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'level': event.level,
        'prefix': event.prefix,
        'message': event.text,
      };

      log(json.encode(logEntry));

      // if (event.level == 'error') {
      //   streams[textureId]!.addError(PlatformException(
      //     code: event.level.toString(),
      //     message: event.text,
      //   ));
      // }
    });
    players[textureId]!.stream.width.listen((event) {
      if (players[textureId]!.state.duration == Duration.zero) {
        return;
      }

      // print("init width,,");
      if ((!durations.containsKey(textureId) ||
              (durations[textureId] ?? 0) !=
                  players[textureId]!.state.duration.inMicroseconds) &&
          (players[textureId]!.state.width != null &&
              players[textureId]!.state.height != null)) {
        durations[textureId] =
            players[textureId]!.state.duration.inMicroseconds;

        streams[textureId]!.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: players[textureId]!.state.duration,
          size: Size(players[textureId]!.state.width!.toDouble(),
              players[textureId]!.state.height!.toDouble()),
          rotationCorrection: 0,
        ));
      }
    });
    players[textureId]!.stream.height.listen((event) {
      // print("init height,,");
      if (players[textureId]!.state.duration == Duration.zero) {
        return;
      }

      if ((!durations.containsKey(textureId) ||
              (durations[textureId] ?? 0) !=
                  players[textureId]!.state.duration.inMicroseconds) &&
          (players[textureId]!.state.width != null &&
              players[textureId]!.state.height != null)) {
        durations[textureId] =
            players[textureId]!.state.duration.inMicroseconds;

        streams[textureId]!.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: players[textureId]!.state.duration,
          size: Size(players[textureId]!.state.width!.toDouble(),
              players[textureId]!.state.height!.toDouble()),
          rotationCorrection: 0,
        ));
      }
    });
    players[textureId]!.stream.duration.listen((event) {
      if ((durations[textureId] ?? 0) > 0) {
        // print("$textureId is live from duration");
        isLive[textureId] = true;
        return;
      }
      // print("platform duration,${event.inMicroseconds}, old one is ${durations[textureId] ?? 0}");
      if (event != Duration.zero) {
        if ((!durations.containsKey(textureId) ||
                (durations[textureId] ?? 0) != event.inMicroseconds) &&
            (players[textureId]!.state.width != null &&
                players[textureId]!.state.height != null)) {
          // print("init");
          durations[textureId] = event.inMicroseconds;
          streams[textureId]!.add(VideoEvent(
            eventType: VideoEventType.initialized,
            duration: players[textureId]!.state.duration,
            size: Size(players[textureId]!.state.width!.toDouble(),
                players[textureId]!.state.height!.toDouble()),
            rotationCorrection: 0,
          ));
        }
      }
    });
    players[textureId]!.stream.buffering.listen((event) {
      if (event) {
        streams[textureId]!.add(VideoEvent(
          eventType: VideoEventType.bufferingStart,
        ));
      } else {
        streams[textureId]!
            .add(VideoEvent(eventType: VideoEventType.bufferingEnd));
      }
    });
    players[textureId]!.stream.buffer.listen((event) {
      streams[textureId]!.add(VideoEvent(
        buffered: [DurationRange(Duration.zero, event)],
        eventType: VideoEventType.bufferingUpdate,
      ));
    });

    players[textureId]!.stream.error.listen((event) {
      // print("isBuffering $event");
      if (!throwErrors) {
        return;
      }
      streams[textureId]!.addError(PlatformException(
        code: "",
        message: event,
      ));
    });
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    if (isLive[textureId] ?? false) {
      // print("$textureId is live");
      return Duration.zero;
    }
    return players[textureId]!.platform!.state.position;
  }

  @override
  Future<void> init() async {
    _disposeAllPlayers();

    // DartVLC.initialize();
  }

  @override
  Future<void> pause(int textureId) async {
    return players[textureId]!.pause();
  }

  @override
  Future<void> play(int textureId) async {
    return players[textureId]!.play();
  }

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    if (isLive[textureId] ?? false) {
      position =
          players[textureId]!.state.duration - Duration(milliseconds: 500);
    }
    return players[textureId]!.seek(position);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    assert(speed > 0);
    return players[textureId]!.setRate(speed);
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    return players[textureId]!.setVolume(volume * 100);
  }

  @override
  Future<void> dispose(int textureId) async {
    // print("disposed player $textureId");
    // players[textureId]!.playbackStream.listen((element) {
    //   print("is playing ${element.isPlaying}");
    // });
    // await players[textureId]!
    //     .playbackStream
    //     .firstWhere((event) => !event.isPlaying);
    pause(textureId);
    players[textureId]!.dispose();
    // controllers[textureId]!.dispose();
    streams[textureId]!.close();
    players.remove(textureId);
    controllers.remove(textureId);
    streams.remove(textureId);
    return;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return streams[textureId]!.stream;
  }

  /// setLooping
  @override
  Future<void> setLooping(int textureId, bool looping) async {
    return players[textureId]!
        .setPlaylistMode(looping ? PlaylistMode.single : PlaylistMode.loop);
  }

  /// Sets the audio mode to mix with other sources (ignored)
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) => Future<void>.value();
}
