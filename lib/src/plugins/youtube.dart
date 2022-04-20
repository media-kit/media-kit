import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

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

class YouTube {
  YouTube({
    int port = 6900,
  }) {
    /// If is debug mode use different port from release mode
    _port = math.Random().nextInt((1 << 16) - 1);
    _create().catchError((exception, stacktrace) {
      print(exception);
      print(stacktrace);
    });
  }

  Future<void> close() => _server.close();

  Future<String> _stream(String id) async {
    await _completer.future;
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
    print('🕊️🕊️🕊️ ${opus ?? aac ?? mp4}');
    return (opus ?? aac ?? mp4)!;
  }

  Future<void> _create() async {
    _server = HttpServer.listenOn(
      await ServerSocket.bind('127.0.0.1', _port),
    );
    _server.listen((request) async {
      switch (request.uri.path) {
        case '/youtube':
          {
            request.response.headers.set(
              'location',
              await _stream(request.uri.queryParameters['id']!),
            );
            request.response.statusCode = 302;
            request.response.close();
            break;
          }
        default:
          break;
      }
    });
    _completer.complete();
  }

  final _completer = Completer();
  late final HttpServer _server;
}

late int _port;

abstract class Plugins {
  static Uri redirect(Uri uri) {
    final string = uri.toString();
    if ((string.contains('.youtube') ||
            string.contains('youtu.be') ||
            string.contains('/youtu')) &&
        string.contains('/')) {
      final path = 'http://127.0.0.1:$_port/youtube?id=';
      if (string.contains('/watch?v=')) {
        return Uri.parse(
            path + string.substring(string.indexOf('=') + 1).split('&').first);
      } else {
        return Uri.parse(path + string.substring(string.indexOf('.be/') + 4));
      }
    }
    return uri;
  }

  static bool isWebMedia(Uri uri) =>
      (uri.toString().contains('.youtube') ||
          uri.toString().contains('youtu.be') ||
          uri.toString().contains('/youtu')) &&
      uri.toString().contains('/');

  static String artwork(
    Uri uri, {
    bool small = false,
  }) {
    final string = uri.toString();
    if (isWebMedia(uri)) {
      // YouTube links of the form https://www.youtube.com/watch?v=abc.
      if (string.contains('/watch?v=')) {
        return 'https://i.ytimg.com/vi/${string.substring(string.indexOf('=') + 1).split('&').first}/${small ? 'mqdefault' : 'maxresdefault'}.jpg';
      }
      // Re-directed YouTube links of the form https://127.0.0.1:6900/youtube?id=abc.
      else if (string.contains('127.0.0.1')) {
        return 'https://i.ytimg.com/vi/${uri.toString().split('=').last}/${small ? 'mqdefault' : 'maxresdefault'}.jpg';
      }
      // YouTube links of the form https://youtu.be/abc/.
      else {
        return 'https://i.ytimg.com/vi/${string.substring(string.indexOf('.be/') + 4).split('/').first}/${small ? 'mqdefault' : 'maxresdefault'}.jpg';
      }
    }
    throw FormatException();
  }
}
