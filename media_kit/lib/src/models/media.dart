/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:uri_parser/uri_parser.dart';

import 'package:media_kit/src/models/playable.dart';

HashMap<String, Media> medias = HashMap<String, Media>();
HashMap<String, double> bitrates = HashMap<String, double>();

/// {@template media}
///
/// Media
/// -----
///
/// A [Media] object to open inside a [Player] for playback.
///
/// ```dart
/// final playable = Media('file:///C:/Users/Hitesh/Video/Sample.mkv');
/// ```
///
/// {@endtemplate}
class Media extends Playable {
  /// URI of the [Media].
  final String uri;

  /// Additional optional user data.
  final dynamic extras;

  /// {@macro media}
  Media(
    String resource, {
    this.extras,
  }) : uri = normalizeURI(resource) {
    medias[uri] = this;
  }

  /// Normalizes the passed URI.
  static String normalizeURI(String uri) {
    // Handle asset:// scheme. Only for Flutter.
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
      //
      throw UnimplementedError(
        '$_kAssetScheme is not supported on ${Platform.operatingSystem}',
      );
    }
    // Keep the resulting URI same as used internally in libmpv.
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
