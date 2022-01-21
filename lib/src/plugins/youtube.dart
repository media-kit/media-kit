import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

var youtube = _YouTube();

const String _kRequestAuthority = 'music.youtube.com';
const String _kRequestKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
const Map<String, String> _kRequestHeaders = {
  'accept': '*/*',
  'accept-language': 'en-GB,en;q=0.9,en-US;q=0.8',
  'content-type': 'application/json',
  'dpr': '2',
  'sec-ch-ua-arch': '',
  'sec-fetch-dest': 'empty',
  'sec-fetch-mode': 'same-origin',
  'sec-fetch-site': 'same-origin',
  'x-origin': 'https://music.youtube.com',
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

class _YouTube {
  Future<String?> id(String uri) async {
    String? id;
    if (uri.contains('youtu') && uri.contains('/')) {
      if (uri.contains('/watch?v=')) {
        id = uri.substring(uri.indexOf('=') + 1);
      } else {
        id = uri.substring(uri.indexOf('/') + 1);
      }
    }
    return id?.split('&').first.split('/').first;
  }

  Future<String> stream(String id) async {
    var response = await http.post(
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
    var body = convert.jsonDecode(response.body)['streamingData'];
    String? opus;
    String? mp4;
    String? aac;
    for (var format in body['adaptiveFormats']) {
      if (format['itag'] == 251) opus = format['url'];
      if (format['itag'] == 18) mp4 = format['url'];
      if (format['itag'] == 140) aac = format['url'];
    }
    return (opus ?? aac ?? mp4)!;
  }
}
