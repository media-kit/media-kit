/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uri_parser/uri_parser.dart';

Map<String, Media> medias = {};
Map<String, double> bitrates = {};

/// ## Media
/// A [Media] object to open inside a [Player] instance using [Player.open] method for playback.
///
/// ```dart
/// final playable = Media('https://www.example.com/music.mp3');
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
  /// final playable = Media('https://www.example.com/music.mp3');
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
    // Match the URI style with internal libmpv URI style.

    // Handle asset:// scheme.
    if (uri.startsWith(_kAssetScheme)) {
      if (Platform.isWindows || Platform.isLinux) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          'data',
          'flutter_assets',
          uri.split(_kAssetScheme).last,
        );
      } else if (Platform.isMacOS) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          '..',
          'Frameworks',
          'App.framework',
          'Resources',
          'flutter_assets',
          uri.split(_kAssetScheme).last,
        );
      } else if (Platform.isIOS) {
        return path.join(
          path.dirname(Platform.resolvedExecutable),
          'Frameworks',
          'App.framework',
          'flutter_assets',
          uri.split(_kAssetScheme).last,
        );
      }
      throw UnimplementedError(
        '$_kAssetScheme is not supported on ${Platform.operatingSystem}',
      );
    }
    // [File] or network URIs.
    final parser = URIParser(uri);
    switch (parser.type) {
      case URIType.file:
        {
          return parser.file!.path;
        }
      case URIType.network:
        {
          return parser.uri!.toString();
        }
      default:
        return uri;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Media) {
      return other.uri == uri || getCleanedURI(other.uri) == getCleanedURI(uri);
    }
    return false;
  }

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'Media($uri, extras: $extras)';

  static const _kAssetScheme = 'asset://';
}
