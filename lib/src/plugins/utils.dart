/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:libmpv/src/plugins/youtube.dart';

abstract class LibmpvPluginUtils {
  /// Redirects actual YouTube video URL to a locally running HTTP
  /// server, which will serve the corresponding media stream URL.
  static Uri redirect(Uri uri) {
    // youtu.be/watch?v=abcdefghi.
    if (uri.authority.contains('youtu.be')) {
      return Uri.http(
        '127.0.0.1:${YouTube.instance.port}',
        '/youtube',
        {
          'id': uri.path.replaceAll('/', ''),
        },
      );
    }
    // www.youtube.com/watch?v=abcdefghi.
    else if (uri.authority.contains('youtube.com') &&
        uri.path.contains('/watch') &&
        uri.queryParameters.containsKey('v')) {
      return Uri.http(
        '127.0.0.1:${YouTube.instance.port}',
        '/youtube',
        {
          'id': uri.queryParameters['v'],
        },
      );
    }
    return uri;
  }

  /// Whether this [Uri] is supported by any of the plugins present in `package:libmpv`.
  ///
  static bool isSupported(Uri uri) => <bool>[
        uri.authority.contains('youtu.be'),
        uri.authority.contains('youtube.com') &&
            uri.path.contains('/watch') &&
            uri.queryParameters.containsKey('v'),
        (uri.authority.contains('localhost') ||
                uri.authority.contains('127.0.0.1')) &&
            uri.path.contains('/youtube') &&
            uri.queryParameters.containsKey('id'),
      ].any((e) => e);

  /// Gets the thumbnail URL for the given YouTube video URL.
  ///
  /// Passing [small] as `true` will result in a smaller sized image.
  ///
  static Uri thumbnail(
    Uri uri, {
    bool small = false,
  }) {
    // youtu.be/watch?v=abcdefghi.
    if (uri.authority.contains('youtu.be')) {
      return Uri.http(
        'i.ytimg.com',
        '/vi/${uri.path.replaceAll('/', '')}/${small ? 'mqdefault' : 'maxresdefault'}.jpg',
      );
    }
    // www.youtube.com/watch?v=abcdefghi.
    else if (uri.authority.contains('youtube.com') &&
        uri.path.contains('/watch') &&
        uri.queryParameters.containsKey('v')) {
      return Uri.http(
        'i.ytimg.com',
        '/vi/${uri.queryParameters['v']}/${small ? 'mqdefault' : 'maxresdefault'}.jpg',
      );
    }
    // 127.0.0.1:3000/youtube?id=abcdefghi.
    else if ((uri.authority.contains('localhost') ||
            uri.authority.contains('127.0.0.1')) &&
        uri.path.contains('/youtube') &&
        uri.queryParameters.containsKey('id')) {
      return Uri.http(
        'i.ytimg.com',
        '/vi/${uri.queryParameters['id']}/${small ? 'mqdefault' : 'maxresdefault'}.jpg',
      );
    }
    throw FormatException(
      'LibmpvPluginUtils.thumbnail: $uri is not supported',
    );
  }
}
