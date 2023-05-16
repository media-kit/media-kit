/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:collection';
import 'package:path/path.dart' as path;
import 'package:uri_parser/uri_parser.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/android_asset_loader.dart';

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
/// final player = Player();
/// final playable = Media('file:///C:/Users/Hitesh/Video/Sample.mkv');
/// await player.open(playable);
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
    if (uri.startsWith(_kAssetScheme)) {
      // Handle asset:// scheme. Only for Flutter.
      final key = encodeAssetKey(uri);
      final String asset;
      if (Platform.isWindows) {
        asset = path.normalize(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            'data',
            'flutter_assets',
            key,
          ),
        );
      } else if (Platform.isLinux) {
        asset = path.normalize(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            'data',
            'flutter_assets',
            key,
          ),
        );
      } else if (Platform.isMacOS) {
        asset = path.normalize(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            '..',
            'Frameworks',
            'App.framework',
            'Resources',
            'flutter_assets',
            key,
          ),
        );
      } else if (Platform.isIOS) {
        asset = path.normalize(
          path.join(
            path.dirname(Platform.resolvedExecutable),
            'Frameworks',
            'App.framework',
            'flutter_assets',
            key,
          ),
        );
      } else if (Platform.isAndroid) {
        asset = path.normalize(
          AndroidAssetLoader.loadSync(
            path.join(
              'flutter_assets',
              key,
            ),
          ),
        );
      } else {
        throw UnimplementedError(
          '$_kAssetScheme is not supported on ${Platform.operatingSystem}',
        );
      }
      if (!File(asset).existsSync_()) {
        throw Exception('Unable to load asset: $asset');
      }
      uri = asset;
    }
    // Keep the resulting URI normalization same as used by libmpv internally.
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

  static String encodeAssetKey(String uri) {
    String key = uri.split(_kAssetScheme).last;
    if (key.startsWith('/')) {
      key = key.substring(1);
    }
    // https://github.com/alexmercerind/media_kit/issues/121
    return key.split('/').map((e) => Uri.encodeComponent(e)).join('/');
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
