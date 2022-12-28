/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:uri_parser/uri_parser.dart';

HashMap<String, Media> medias = HashMap<String, Media>();
HashMap<String, double> bitrates = HashMap<String, double>();

/// {@template media}
///
/// Media
/// -----
///
/// A [Media] object to open inside a [Player] instance using [Player.open] method for playback.
///
/// ```dart
/// final playable = Media('https://www.example.com/music.mp3');
/// ```
///
/// {@endtemplate}
class Media {
  /// URI of the [Media].
  final String uri;

  /// Additional optional user data.
  final dynamic extras;

  /// {@macro media}
  Media(
    String resource, {
    this.extras,
  }) : uri = getCleanedURI(resource) {
    medias[uri] = this;
  }

  /// Returns normalized & cleaned-up [uri].
  static String getCleanedURI(String uri) {
    // Match the URI style with internal libmpv URI style.
    // Handle asset:// scheme.
    if (uri.startsWith(_kAssetScheme)) {
      if (Platform.isWindows || Platform.isLinux) {
        return Uri.file(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            'data',
            'flutter_assets',
            path.normalize(uri.split(_kAssetScheme).last),
          ),
        ).toString();
      } else if (Platform.isMacOS) {
        return Uri.file(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            '..',
            'Frameworks',
            'App.framework',
            'Resources',
            'flutter_assets',
            path.normalize(uri.split(_kAssetScheme).last),
          ),
        ).toString();
      } else if (Platform.isIOS) {
        return Uri.file(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            'Frameworks',
            'App.framework',
            'flutter_assets',
            path.normalize(uri.split(_kAssetScheme).last),
          ),
        ).toString();
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

  /// For comparing with other [Media] instances.
  @override
  bool operator ==(Object other) {
    if (other is Media) {
      return other.uri == uri;
    }
    return false;
  }

  /// For comparing with other [Media] instances.
  @override
  int get hashCode => uri.hashCode;

  /// Prettier [print] logging.
  @override
  String toString() => 'Media($uri, extras: $extras)';

  /// URI scheme used to identify Flutter assets.
  static const _kAssetScheme = 'asset://';
}
