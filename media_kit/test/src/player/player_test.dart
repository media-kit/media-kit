import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:collection';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

import 'package:media_kit/src/media_kit.dart';
import 'package:media_kit/src/player/player.dart';
import 'package:media_kit/src/models/playlist.dart';
import 'package:media_kit/src/models/media/media.dart';
import 'package:media_kit/src/player/libmpv/player/player.dart';

import '../../common/sources.dart';

void main() {
  setUp(() async {
    MediaKit.ensureInitialized();
    await sources.prepare();
  });
  test(
    'player-platform',
    () {
      final player = Player();
      expect(
        player.platform,
        isA<libmpvPlayer>(),
      );
    },
  );
  test(
    'player-handle',
    () {
      final player = Player();
      expect(
        player.handle,
        completes,
      );
    },
  );
  test(
    'player-open-playable-media',
    () async {
      final player = Player();

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.file[0]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
            true,
          ],
        ),
      );
      expect(
        player.streams.completed,
        emitsInOrder(
          [
            false,
          ],
        ),
      );

      await player.open(Media(sources.file[0]));
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist',
    () async {
      final player = Player();

      final playlist = Playlist(
        [
          for (int i = 0; i < sources.file.length; i++) Media(sources.file[i]),
        ],
      );

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            for (int i = 0; i < sources.file.length; i++)
              playlist.copyWith(index: i),
          ],
        ),
      );

      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
            false,
            true,
            false,
            true,
          ],
        ),
      );
      expect(
        player.streams.completed,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
            false,
            true,
            false,
          ],
        ),
      );

      await player.open(playlist);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-play-false',
    () async {
      final player = Player();

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.file[0]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
          ],
        ),
      );

      await player.open(
        Media(sources.file[0]),
        play: false,
      );
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-play-false',
    () async {
      final player = Player();

      final playlist = Playlist(
        [
          for (int i = 0; i < sources.file.length; i++) Media(sources.file[i]),
        ],
      );

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            playlist,
          ],
        ),
      );
      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
          ],
        ),
      );

      await player.open(
        playlist,
        play: false,
      );
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-play-false-play',
    () async {
      final player = Player();

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.file[0]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
            true,
          ],
        ),
      );
      expect(
        player.streams.completed,
        emitsInOrder(
          [
            false,
          ],
        ),
      );

      await player.open(
        Media(sources.file[0]),
        play: false,
      );
      await player.play();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-play-false-play',
    () async {
      final player = Player();

      final playlist = Playlist(
        [
          for (int i = 0; i < sources.file.length; i++) Media(sources.file[i]),
        ],
      );

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            for (int i = 0; i < sources.file.length; i++)
              playlist.copyWith(index: i),
          ],
        ),
      );

      expect(
        player.streams.playing,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
            false,
            true,
            false,
            true,
          ],
        ),
      );
      expect(
        player.streams.completed,
        emitsInOrder(
          [
            false,
            true,
            false,
            true,
            false,
            true,
            false,
          ],
        ),
      );

      await player.open(
        playlist,
        play: false,
      );
      await player.play();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-extras',
    () async {
      final player = Player();

      final expectExtras = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Map<String, String>>());
          final extras = value as Map<String, String>;
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

      player.streams.playlist.listen((e) {
        if (e.index >= 0) {
          expectExtras(e.medias[0].extras);
        }
      });

      await player.open(
        Media(
          sources.file[0],
          extras: {
            'foo': 'bar',
            'baz': 'qux',
          },
        ),
      );
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
          expect(value, isA<Map<String, String>>());
          final extras = value as Map<String, String>;
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
        count: sources.file.length,
      );

      player.streams.playlist.listen(
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
            for (int i = 0; i < sources.file.length; i++)
              Media(
                sources.file[i],
                extras: {
                  'i': i.toString(),
                },
              ),
          ],
        ),
      );
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-media-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = Random().nextInt(1 << 16 - 1);

      final expectHTTPHeaders = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;

          expect(headers.value('X-Foo'), 'Bar');
          expect(headers.value('X-Baz'), 'Qux');
        },
      );

      final expectPlaylist = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Playlist>());
          final playlist = value as Playlist;
          expect(
            ListEquality().equals(
              playlist.medias,
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
          final path = sources.file[i];
          e.response.headers.add('Content-Type', 'video/mp4');
          e.response.headers.add('Accept-Ranges', 'bytes');
          File(path).openRead().pipe(e.response);
        },
      );

      player.streams.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlaylist(e);
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
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-http-headers',
    () async {
      final player = Player();

      final address = '127.0.0.1';
      final port = Random().nextInt(1 << 16 - 1);

      final expectHTTPHeaders = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<HttpHeaders>());
          final headers = value as HttpHeaders;
          expect(headers.value('X-Foo'), '$i');
        },
        count: sources.file.length,
      );
      final expectPlaylist = expectAsync2(
        (value, i) {
          print(value);
          expect(value, isA<Playlist>());
          final playlist = value as Playlist;
          expect(playlist.index, i);
          expect(
            ListEquality().equals(
              playlist.medias,
              [
                for (int i = 0; i < sources.file.length; i++)
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
        count: sources.file.length,
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

      player.streams.playlist.listen((e) {
        if (e.index >= 0) {
          expectPlaylist(e, e.index);
        }
      });

      await player.open(
        Playlist(
          [
            for (int i = 0; i < sources.file.length; i++)
              Media(
                'http://$address:$port/$i',
                httpHeaders: {
                  'X-Foo': '$i',
                },
              ),
          ],
        ),
      );
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-play-after-completed',
    () async {
      final completer = Completer();

      final player = Player();

      player.streams.completed.listen((event) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await player.open(Media(sources.file[0]));

      await completer.future;

      final expectPosition = expectAsync1(
        (value) {
          print(value);
          expect(value, isA<Duration>());
        },
        count: 1,
        max: -1,
      );

      player.streams.position.listen((event) async {
        await player.dispose();
        expectPosition(event);
      });

      await player.play();
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-while-playing',
    () async {
      final player = Player();

      expect(
        player.streams.playlist,
        emitsInOrder(
          [
            Playlist(
              [
                Media(sources.file[0]),
              ],
              index: 0,
            ),
            Playlist(
              [
                Media(sources.file[1]),
              ],
              index: 0,
            ),
          ],
        ),
      );
      expect(
        player.streams.playing,
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
        player.streams.completed,
        emitsInOrder(
          [
            false,
            true,
          ],
        ),
      );

      await player.open(Media(sources.file[0]));

      await Future.delayed(const Duration(seconds: 5));

      await player.open(Media(sources.file[1]));
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
  test(
    'player-open-playable-playlist-non-zero-index',
    () async {
      final player = Player();

      final playlist = Playlist(
        [
          for (int i = 0; i < sources.file.length; i++) Media(sources.file[i]),
        ],
        index: sources.file.length - 1,
      );

      expect(
        player.streams.playlist,
        emitsInAnyOrder(
          [
            playlist,
          ],
        ),
      );

      await player.open(playlist);
    },
    timeout: Timeout(const Duration(minutes: 1)),
  );
}
