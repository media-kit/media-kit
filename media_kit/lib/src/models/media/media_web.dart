/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:collection';

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
    // TODO(@alexmercerind): Add support for assets on Flutter Web.
    // if (uri.startsWith(_kAssetScheme)) {
    //   // Handle asset:// scheme. Only for Flutter.
    //   final key = encodeAssetKey(uri);
    // }
    return uri;
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
