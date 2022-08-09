/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';

import 'package:path/path.dart' as path;

Map<String, Media> medias = {};

/// ## Media
/// A [Media] object to open inside a [Player] instance using [Player.open] method for playback.
///
/// ```dart
/// var media = Media('https://www.example.com/music.mp3');
/// ```
///
class Media {
  /// URI of the [Media].
  final String uri;

  /// Additional optional user data.
  final dynamic extras;

  /// ## Media
  /// A [Media] object to open inside a [Player] instance using [Player.open] method for playback.
  ///
  /// ```dart
  /// var media = Media('https://www.example.com/music.mp3');
  /// ```
  ///
  Media(
    this.uri, {
    this.extras,
  }) {
    medias[uri] = this;
    // Cleaned up [Media] [uri] to match the format returned by libmpv internally.
    medias[getCleanedURI(uri)] = this;
  }

  static String getCleanedURI(String uri) {
    // Match with format retrieved by `mpv_get_property`.
    // Only applicable on Windows.
    if (uri.startsWith('file://')) {
      return Uri.parse(uri).toFilePath().replaceAll('\\', '/');
    }
    // Only applicable on Windows.
    else if (uri.contains('\\') && Platform.isWindows) {
      return uri.replaceAll('\\', '/');
    }
    // Handle `asset://` separately.
    else if (uri.startsWith('asset://')) {
      if (Platform.isWindows || Platform.isLinux) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          'data',
          'flutter_assets',
          uri.split('asset://').last,
        );
      } else if (Platform.isMacOS) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          '..',
          'Frameworks',
          'App.framework',
          'Resources',
          'flutter_assets',
          uri.split('asset://').last,
        );
      } else if (Platform.isIOS) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          'Frameworks',
          'App.framework',
          'flutter_assets',
          uri.split('asset://').last,
        );
      }
      throw UnimplementedError(
        'asset:// is not supported on ${Platform.operatingSystem}',
      );
    }
    // Other kinds of URIs e.g. HTTP, FTP, etc. are directly fed into libmpv.
    else {
      return uri;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Media) {
      return other.uri == uri;
    }
    return false;
  }

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'Media($uri, extras: $extras)';
}
