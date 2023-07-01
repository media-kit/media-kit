import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:media_kit/src/models/track.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/models/audio_device.dart';
import 'package:media_kit/src/models/audio_params.dart';
import 'package:media_kit/src/models/playlist_mode.dart';

import 'package:media_kit/src/media_kit.dart';
import 'package:media_kit/src/player/player.dart';
import 'package:media_kit/src/player/platform_player.dart';
import 'package:media_kit/src/player/web/player/player.dart';
import 'package:media_kit/src/player/libmpv/player/player.dart';

import '../../common/sources.dart';

void main() {
  setUp(() async {
    MediaKit.ensureInitialized();
    await sources.prepare();
    if (UniversalPlatform.isWeb) {
      // For preventing "DOMException: play() failed because the user didn't interact with the document first." in unit-tests running on web.
      webPlayer.muted = true;
    }
  });
  test(
    'player-platform',
    () {
      final player = Player();
      expect(
        player.platform,
        isA<libmpvPlayer>(),
      );

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-platform',
    () {
      final player = Player();
      expect(
        player.platform,
        isA<webPlayer>(),
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-handle',
    () {
      final player = Player();
      expect(
        player.handle,
        completes,
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-configuration-ready-callback',
    () {
      final expectReady = expectAsync0(() {});

      final player = Player(
        configuration: PlayerConfiguration(
          ready: () {
            expectReady();
          },
        ),
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-open-playable-media',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // -> 1
            false,
            true,
            // -> 2
            false,
            true,
            // -> 3
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // -> 1
            true,
            false,
            // -> 2
            true,
            false,
            // -> 3
            true,
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-open-playable-media-play-false',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.platform[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-play-false',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable, play: false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-play-false-play',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            // Player.play
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            // Player.play
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.platform[0]),
        play: false,
      );
      await player.play();

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );

  test(
    'player-open-playable-playlist-play-false-play',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // -> 1
            false,
            true,
            // -> 2
            false,
            true,
            // -> 3
            false,
            true,
            // EOF
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // -> 1
            true,
            false,
            // -> 2
            true,
            false,
            // -> 3
            true,
            false,
            // EOF
            true,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(playable, play: false);
      await player.play();

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-open-playable-media-extras',
    () async {
      final player = Player();

      final expectExtras = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Map<String, dynamic>>());
          final extras = value as Map<String, dynamic>;
          expect(
            MapEquality().equals(
              extras,
              {
                'foo': 'bar',
                'baz': 'qux',
              },
            ),
            true,
          );
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectExtras(e.medias[0].extras);
        }
      });

      await player.open(
        Media(
          sources.platform[0],
          extras: {
            'foo': 'bar',
            'baz': 'qux',
          },
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-extras',
    () async {
      final player = Player();

      final expectExtras = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<Map<String, dynamic>>());
          final extras = value as Map<String, dynamic>;
          expect(
            MapEquality().equals(
              extras,
              {
                'i': i.toString(),
              },
            ),
            true,
          );
        },
        count: sources.platform.length,
      );

      player.stream.playlist.listen(
        (e) {
          if (e.index >= 0) {
            expectExtras(
              e.medias[e.index].extras,
              e.index,
            );
          }
        },
      );

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.platform.length; i++)
              Media(
                sources.platform[i],
                extras: {
                  'i': i.toString(),
                },
              ),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-open-playable-media-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = 8081;

      final expectHTTPHeaders = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;

          expect(headers.value('X-Foo'), 'Bar');
          expect(headers.value('X-Baz'), 'Qux');
        },
      );

      final expectPlayable = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Playlist>());
          final playable = value as Playlist;
          expect(
            ListEquality().equals(
              playable.medias,
              [
                Media(
                  'http://$address:$port/0',
                  httpHeaders: {
                    'X-Foo': 'Bar',
                    'X-Baz': 'Qux',
                  },
                ),
              ],
            ),
            true,
          );
        },
      );

      final completed = HashSet<int>();

      final socket = await ServerSocket.bind(address, port);
      final server = HttpServer.listenOn(socket);
      server.listen(
        (e) async {
          final i = int.parse(e.uri.path.split('/').last);
          if (!completed.contains(i)) {
            completed.add(i);
            expectHTTPHeaders(e.headers);
          }
          final path = sources.platform[i];
          e.response.headers.add('Content-Type', 'video/mp4');
          e.response.headers.add('Accept-Ranges', 'bytes');
          File(path).openRead().pipe(e.response);
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlayable(e);
        }
      });

      await player.open(
        Media(
          'http://$address:$port/0',
          httpHeaders: {
            'X-Foo': 'Bar',
            'X-Baz': 'Qux',
          },
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
      await server.close();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-open-playable-playlist-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = 8082;

      final expectHTTPHeaders = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;
          expect(headers.value('X-Foo'), '$i');
        },
        count: sources.platform.length,
      );
      final expectPlayable = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<Playlist>());
          final playable = value as Playlist;
          expect(playable.index, i);
          expect(
            ListEquality().equals(
              playable.medias,
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(
                    'http://$address:$port/$i',
                    httpHeaders: {
                      'X-Foo': '$i',
                    },
                  ),
              ],
            ),
            true,
          );
        },
        count: sources.platform.length,
      );

      final completed = HashSet<int>();

      final socket = await ServerSocket.bind(address, port);
      final server = HttpServer.listenOn(socket);
      server.listen(
        (e) async {
          final i = int.parse(e.uri.path.split('/').last);
          if (!completed.contains(i)) {
            completed.add(i);
            expectHTTPHeaders(e.headers, i);
          }
          final data = sources.bytes[i];
          e.response.headers.contentLength = data.length;
          e.response.headers.contentType = ContentType('video', 'mp4');
          e.response.add(data);
          await e.response.flush();
          await e.response.close();
        },
      );

      player.stream.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlayable(e, e.index);
        }
      });

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.platform.length; i++)
              Media(
                'http://$address:$port/$i',
                httpHeaders: {
                  'X-Foo': '$i',
                },
              ),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
      await server.close();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-play-after-completed',
    () async {
      // Only applicable for PlaylistMode.none.

      final completer = Completer();

      final player = Player();

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.play
            true,
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.play
            false,
          ],
        ),
      );

      player.stream.completed.listen((event) {
        if (!completer.isCompleted) {
          if (event) {
            completer.complete();
          }
        }
      });

      await player.open(Media(sources.platform[0]));

      // Wait for EOF.
      await completer.future;

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      await Future.delayed(const Duration(seconds: 5));

      // Begin test.

      await player.play();

      // End test.

      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-seek-after-completed',
    () async {
      final completer = Completer();

      final player = Player();

      expect(
        player.stream.playing,
        emitsInOrder(
          [
            // Player.open
            false,
            true,
            // EOF
            false,
            // Player.seek
            // ---------
          ],
        ),
      );
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            // Player.open
            false,
            // EOF
            true,
            // Player.seek
            false,
          ],
        ),
      );

      player.stream.completed.listen((event) {
        if (!completer.isCompleted) {
          if (event) {
            completer.complete();
          }
        }
      });

      await player.open(Media(sources.platform[0]));

      // Wait for EOF.
      await completer.future;

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
          final position = value as Duration;
          expect(position, Duration.zero);
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      // Begin test.

      await player.seek(Duration.zero);

      // End test.

      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-while-playing',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            Playlist(
              [
                Media(sources.platform[1]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.stream.playing,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
          ],
        ),
      );
      // NOTE: Not emitted when the playable is changed mid-playback. Only upon end of file.
      expect(
        player.stream.completed,
        emitsInOrder(
          [
            false,
            true,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      await Future.delayed(const Duration(seconds: 5));

      await player.open(Media(sources.platform[1]));

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-non-zero-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
        index: sources.platform.length - 1,
      );

      expect(
        player.stream.playlist,
        emits(
          playable,
        ),
      );

      await player.open(playable);

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
    // TODO: Flaky on GNU/Linux CI.
    skip: true,
  );
  test(
    'player-audio-devices',
    () async {
      final player = Player();

      final expectAudioDevices = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<List<AudioDevice>>());
          final devices = value as List<AudioDevice>;
          expect(devices, isNotEmpty);
          expect(devices.first, equals(AudioDevice.auto()));
        },
        count: 1,
        max: -1,
      );

      player.stream.audioDevices.listen((event) async {
        expectAudioDevices(event);
      });

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-audio-device',
    () async {
      final player = Player();

      final devices = await player.stream.audioDevices.first;

      if (devices.length > 1) {
        expect(devices, isNotEmpty);
        expect(devices.first, equals(AudioDevice.auto()));

        final expectAudioDevice = expectAsync2(
          (device, i) {
            print(device);
            expect(device, isA<AudioDevice>());
            expect(device, equals(devices[i as int]));
          },
          count: devices.length,
        );

        int? index;

        player.stream.audioDevice.listen((event) async {
          expectAudioDevice(event, index);
        });

        for (int i = devices.length - 1; i >= 0; i--) {
          index = i;

          await player.setAudioDevice(devices[i]);

          await Future.delayed(const Duration(seconds: 1));
        }
      }

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-audio-device',
    () async {
      final player = Player();

      expect(
        player.setAudioDevice(AudioDevice.auto()),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-volume',
    () async {
      final player = Player();

      final expectVolume = expectAsync2(
        (volume, i) {
          print(volume);
          expect(volume, isA<double>());
          expect(i, isA<int>());
          volume = volume as double;
          i = i as int;
          expect(
            /* This round() is solely needed because floating-point arithmetic on JavaScript is retarded. */
            volume.round(),
            equals(i),
          );
        },
        count: 100,
      );

      int? index;

      player.stream.volume.listen((event) {
        expectVolume(event, index);
      });

      for (int i = 0; i < 100; i++) {
        index = i;

        await player.setVolume(i.toDouble());

        await Future.delayed(const Duration(milliseconds: 100));
      }

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-rate',
    () async {
      final player = Player();

      final test = List.generate(10, (index) => 0.25 * (index + 1));

      final expectRate = expectAsync2(
        (rate, i) {
          print(rate);
          expect(rate, isA<double>());
          expect(i, isA<int>());
          expect(rate, equals(test[i as int]));
        },
        count: test.length,
      );

      int? index;

      player.stream.rate.listen((event) {
        expectRate(event, index);
      });

      for (int i = 0; i < test.length; i++) {
        index = i;

        await player.setRate(test[i]);

        await Future.delayed(const Duration(milliseconds: 20));
      }

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-pitch-disabled',
    () async {
      final player = Player();

      expect(player.setPitch(1.0), throwsArgumentError);

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-enabled',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      final test = List.generate(10, (index) => 0.25 * (index + 1));

      final expectPitch = expectAsync2(
        (pitch, i) {
          print(pitch);
          expect(pitch, isA<double>());
          expect(i, isA<int>());
          expect(pitch, equals(test[i as int]));
        },
        count: test.length,
      );

      int? index;

      player.stream.pitch.listen((event) {
        expectPitch(event, index);
      });

      for (int i = 0; i < test.length; i++) {
        index = i;

        await player.setPitch(test[i]);

        await Future.delayed(const Duration(milliseconds: 20));
      }

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-enabled',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        player.setPitch(1.0),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-playlist-mode',
    () async {
      final player = Player();

      expect(
        player.stream.playlistMode,
        emitsInOrder(
          [
            ...PlaylistMode.values,
          ],
        ),
      );

      for (final value in PlaylistMode.values) {
        await player.setPlaylistMode(value);
      }

      addTearDown(player.dispose);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-jump',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );
      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            TypeMatcher<Playlist>().having(
              (playlist) => playlist.index,
              'index',
              equals(0),
            ),
            // Player.jump
            TypeMatcher<Playlist>().having(
              (playlist) => playlist.index,
              'index',
              equals(2),
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(2);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-move',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.move
            Playlist(move(playable.medias, 1, 3)),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.move(1, 3);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-index-transitions-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-index-transitions-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 (does not change)
            playable.copyWith(index: 0),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 1));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1, seconds: 30)),
  );
  test(
    'player-index-transitions-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),

            // must loop back to index: 0

            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      await Future.delayed(const Duration(minutes: 2, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 5)),
  );
  test(
    'player-next-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-next-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
            emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-next-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),

            // must loop back to index: 0

            // index: 0 -> sources.platform.length - 1
            for (int i = 0; i < sources.platform.length; i++)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.next();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 15));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
            // Cannot test (since index keeps transitioning):
            // emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
            // Cannot test (since index keeps transitioning):
            // emitsDone,
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-previous-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );
      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            playable,
            // index: sources.platform.length - 1 -> 0
            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),

            // must loop back to index: sources.platform.length - 1

            for (int i = sources.platform.length - 1; i >= 0; i--)
              playable.copyWith(index: i),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        try {
          await player.previous();
        } catch (_) {}
      });

      await Future.delayed(const Duration(seconds: 45));

      timer.cancel();
      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-add',
    () async {
      final player = Player();

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            Playlist(
              [
                Media(sources.platform[0]),
              ],
              index: 0,
            ),
            // Player.add
            Playlist(
              [
                Media(sources.platform[0]),
                Media(sources.platform[1]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                Media(sources.platform[0]),
                Media(sources.platform[1]),
              ],
              index: 1,
            ),
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.platform[0]));

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.add(Media(sources.platform[1]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-before-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            playable.copyWith(index: 1),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(0);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-after-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 1) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 1) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(1);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.remove
            Playlist(
              [
                // The next item should start playing & index will not increment because the current index is removed.
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 0,
            ),
            // index transition
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != 0) Media(sources.platform[i]),
              ],
              index: 1,
            ),
          ],
        ),
      );

      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(0);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-none',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              index: sources.platform.length - 2,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.none);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-single',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              index: sources.platform.length - 2,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-remove-current-index-stop-playlist-mode-loop',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.jump
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  Media(sources.platform[i]),
              ],
              index: sources.platform.length - 1,
            ),
            // Player.remove
            Playlist(
              [
                for (int i = 0; i < sources.platform.length; i++)
                  if (i != sources.platform.length - 1)
                    Media(sources.platform[i]),
              ],
              // must loop back to index: 0
              index: 0,
            ),
          ],
        ),
      );

      await player.setPlaylistMode(PlaylistMode.loop);
      await player.open(playable);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.jump(sources.platform.length - 1);

      // NOTE: VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.remove(sources.platform.length - 1);

      await Future.delayed(const Duration(seconds: 45));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-set-rate-negative',
    () async {
      final player = Player();

      expect(
        () async => await player.setRate(-1.0),
        throwsArgumentError,
      );

      addTearDown(player.dispose);
    },
  );
  test(
    'player-set-pitch-negative',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        () async => await player.setPitch(-1.0),
        throwsArgumentError,
      );

      addTearDown(player.dispose);
    },
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-set-pitch-negative',
    () async {
      final player = Player(configuration: PlayerConfiguration(pitch: true));

      expect(
        () async => await player.setPitch(-1.0),
        throwsUnsupportedError,
      );

      addTearDown(player.dispose);
    },
    skip: !UniversalPlatform.isWeb,
  );
  test(
    'player-set-shuffle',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      player.stream.playlist.listen(
        (e) {
          print(e.medias.join('\n'));
          print('------------------------------');
        },
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.setShuffle /w true
            TypeMatcher<Playlist>().having(
              (event) => event.medias.toSet(),
              'medias',
              equals(playable.medias.toSet()),
            ),
            // Player.setShuffle /w false
            playable,
          ],
        ),
      );

      await player.open(playable);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.setShuffle(true);

      await Future.delayed(const Duration(seconds: 5));

      // VOLUNTARY DELAY.
      await player.setShuffle(false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-set-shuffle-consecutive',
    () async {
      final player = Player();

      final playable = Playlist(
        [
          for (int i = 0; i < sources.platform.length; i++)
            Media(sources.platform[i]),
        ],
      );

      player.stream.playlist.listen(
        (e) {
          print(e.medias.join('\n'));
          print('------------------------------');
        },
      );

      expect(
        player.stream.playlist,
        emitsInOrder(
          [
            // Player.open
            playable,
            // Player.setShuffle /w true
            TypeMatcher<Playlist>().having(
              (event) => event.medias.toSet(),
              'medias',
              equals(playable.medias.toSet()),
            ),
            // Player.setShuffle /w false
            playable,
          ],
        ),
      );

      await player.open(playable);

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);
      await player.setShuffle(true);

      await Future.delayed(const Duration(seconds: 5));

      // VOLUNTARY DELAY.
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);
      await player.setShuffle(false);

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-file',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.file[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-buffering-network',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(Media(sources.network[0]));

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-file-play-false',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.file[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
    skip: UniversalPlatform.isWeb,
  );
  test(
    'player-buffering-network-play-false',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Media(sources.network[0]),
        play: false,
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-upon-seek',
    () async {
      final player = Player();

      player.stream.buffering.listen((e) => print(e));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // Player.seek: buffering = true
            true,
            // Player.seek: buffering = false
            false,
            // EOF
            true,
            false,
            // Player.dispose
            emitsDone,
          ],
        ),
      );

      // Seek to the end of the stream to trigger buffering.
      player.stream.duration.listen((event) async {
        if (event > Duration.zero) {
          // VOLUNTARY DELAY.
          await Future.delayed(const Duration(seconds: 5));
          await player.seek(event - const Duration(seconds: 10));
        }
      });

      await player.open(
        Media(
          'https://github.com/alexmercerind/media_kit/assets/28951144/efb4057c-6fd3-4644-a0b1-42d5fb420ce9',
        ),
      );

      await Future.delayed(const Duration(seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-buffering-playlist',
    () async {
      final player = Player();

      player.stream.playlist.listen((e) => print(e.index));
      player.stream.completed.listen((e) => print('completed: $e'));
      player.stream.buffering.listen((e) => print('buffering: $e'));

      expect(
        player.stream.buffering,
        emitsInOrder(
          [
            // 0
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 1
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 2
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // 3
            // Player.open: buffering = true
            true,
            // Player.open: buffering = false
            false,
            // EOF
            true,
            false,

            // Player.dispose
            emitsDone,
          ],
        ),
      );

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.network.length; i++)
              Media(sources.network[i]),
          ],
        ),
      );

      await Future.delayed(const Duration(minutes: 1, seconds: 30));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-stop',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.stop();

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      print(player.state);

      expect(player.state.playlist, equals(Playlist([])));
      expect(player.state.playing, equals(false));
      expect(player.state.completed, equals(false));
      expect(player.state.position, equals(Duration.zero));
      expect(player.state.duration, equals(Duration.zero));
      expect(player.state.buffering, equals(false));
      expect(player.state.buffer, equals(Duration.zero));
      expect(player.state.audioParams, equals(const AudioParams()));
      expect(player.state.audioBitrate, equals(null));
      expect(player.state.track, equals(const Track()));
      expect(player.state.tracks, equals(const Tracks()));
      expect(player.state.width, equals(null));
      expect(player.state.height, equals(null));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
  test(
    'player-stop-open',
    () async {
      final player = Player();

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.stop();

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
        },
        count: 1,
        max: -1,
      );

      player.stream.position.listen((event) async {
        print(event);
        expectPosition(event);
      });

      await player.open(Media(sources.platform[0]));

      // VOLUNTARY DELAY.
      await Future.delayed(const Duration(seconds: 5));

      await player.dispose();
    },
    timeout: Timeout(const Duration(minutes: 2)),
  );
}

List<T> move<T>(List<T> list, int from, int to) {
  final map = SplayTreeMap<double, T>.from(
    list.asMap().map((key, value) => MapEntry(key * 1.0, value)),
  );
  final item = map.remove(from * 1.0);
  if (item != null) {
    map[to - 0.5] = item;
  }
  return map.values.toList();
}
