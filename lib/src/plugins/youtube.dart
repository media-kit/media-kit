/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

/// Simple implementation that provides support for YouTube URLs playback inside [Player].
///
/// To make use of it's functionality, pass `yt` argument as `true` when creating a new
/// [Player] for use.
///
/// ```dart
/// final playerWithYouTubePlaybackSupport = Player(yt: true);
/// ```
///
/// The methods of this class should be only accessed through the [instance] singleton.
///
class YouTube {
  /// Public getter for [YouTube] class singleton.
  static YouTube get instance {
    _instance ??= YouTube._();
    return _instance!;
  }

  /// Keeps private [YouTube] object instance.
  static YouTube? _instance;

  YouTube._() {
    port = math.Random().nextInt(1 << 16);
    create().catchError(
      (exception, stacktrace) {
        print(exception);
        print(stacktrace);
      },
    );
  }

  /// Disposes the singleton instance of [YouTube] class.
  Future<void> close() {
    _instance = null;
    return server.close();
  }

  /// Returns media stream URL for the given video [id].
  ///
  Future<String> stream(String id) async {
    await completer.future;
    final response = await http.post(
      Uri.https(
        _kRequestAuthority,
        'youtubei/v1/player',
        {
          'key': _kRequestKey,
        },
      ),
      body: convert.jsonEncode(
        {
          ..._kRequestPayload,
          ...{
            'videoId': id,
          },
        },
      ),
      headers: _kRequestHeaders,
    );
    final body = convert.jsonDecode(response.body)['streamingData'];
    String? opus;
    String? mp4;
    String? aac;
    for (final format in body['adaptiveFormats']) {
      if (format['itag'] == 251) {
        opus = format['url'];
      }
      if (format['itag'] == 140) {
        aac = format['url'];
      }
      if (format['itag'] == 18) {
        mp4 = format['url'];
      }
    }
    return (opus ?? aac ?? mp4)!;
  }

  /// Creates the [_server].
  ///
  Future<void> create() async {
    server = HttpServer.listenOn(
      await ServerSocket.bind(
        '127.0.0.1',
        port,
      ),
    );
    server.listen(
      (request) async {
        switch (request.uri.path) {
          case '/youtube':
            {
              request.response.headers.set(
                'location',
                await stream(
                  request.uri.queryParameters['id']!,
                ),
              );
              request.response.statusCode = HttpStatus.movedTemporarily;
              request.response.close();
              break;
            }
          default:
            break;
        }
      },
    );
    completer.complete();
  }

  /// Avoids any possible race condition of being asked to serve a URL before creation of [HttpServer].
  ///
  final completer = Completer();

  /// The [HttpServer] which is started to redirect YouTube URLs to a locally running server on `127.0.0.1`.
  ///
  /// Then, that local URL redirects to the actual playable media stream (extracted through custom implementation)
  /// using 302 status code i.e. [HttpStatus.movedTemporarily].
  ///
  late final HttpServer server;

  /// Port on which [HttpServer] is set to listening.
  /// Automatically generated randomly between 0 && 65535.
  ///
  late final int port;
}

const String _kRequestAuthority = 'www.youtube.com';
const String _kRequestKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
const Map<String, String> _kRequestHeaders = {
  'accept': '*/*',
  'accept-language': 'en-GB,en;q=0.9,en-US;q=0.8',
  'content-type': 'application/json',
  'dpr': '2',
  'sec-ch-ua-arch': '',
  'sec-fetch-dest': 'empty',
  'sec-fetch-mode': 'same-origin',
  'sec-fetch-site': 'same-origin',
  'x-origin': 'https://www.youtube.com',
  'x-youtube-client-name': '67',
  'x-youtube-client-version': '1.20210823.00.00',
};
const Map<String, dynamic> _kRequestPayload = {
  'context': {
    'client': {
      'clientName': 'ANDROID',
      'clientScreen': 'EMBED',
      'clientVersion': '16.43.34',
    },
    'thirdParty': {
      'embedUrl': 'https://www.youtube.com',
    },
  },
};
