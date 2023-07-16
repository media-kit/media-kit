/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: library_private_types_in_public_api
import 'dart:collection';

import 'package:media_kit/src/models/playable.dart';

/// {@template media}
///
/// Media
/// -----
///
/// A [Media] object to open inside a [Player] for playback.
///
/// ```dart
/// final player = Player();
/// final playable = Media('https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4');
/// await player.open(playable);
/// ```
///
/// {@endtemplate}
class Media extends Playable {
  /// The [Finalizer] is invoked when the [Media] instance is garbage collected.
  /// This has been done to:
  /// 1. Evict the [Media] instance from [cache].
  /// 2. Close the file descriptor created by [AndroidContentUriProvider] to handle content:// URIs on Android.
  static final Finalizer<String> _finalizer = Finalizer<String>((uri) async {
    // Decrement reference count.
    ref[uri] = ((ref[uri] ?? 0) - 1).clamp(0, 1 << 32);
    // Remove [Media] instance from [cache] if reference count is 0.
    if (ref[uri] == 0) {
      cache.remove(uri);
    }
  });

  /// URI of the [Media].
  final String uri;

  /// Additional optional user data.
  ///
  /// Default: `null`.
  final Map<String, dynamic>? extras;

  /// HTTP headers.
  ///
  /// Default: `null`.
  final Map<String, String>? httpHeaders;

  /// {@macro media}
  Media(
    String resource, {
    Map<String, dynamic>? extras,
    Map<String, String>? httpHeaders,
  })  : uri = normalizeURI(resource),
        extras = extras ?? cache[normalizeURI(resource)]?.extras,
        httpHeaders =
            httpHeaders ?? cache[normalizeURI(resource)]?.httpHeaders {
    if (httpHeaders != null) {
      throw UnsupportedError('HTTP headers are not supported on web');
    }
    // Increment reference count.
    ref[uri] = ((ref[uri] ?? 0) + 1).clamp(0, 1 << 32);
    // Store [this] instance in [cache].
    cache[uri] = _MediaCache(
      extras: this.extras,
      httpHeaders: this.httpHeaders,
    );
    // Attach [this] instance to [Finalizer].
    _finalizer.attach(this, uri);
  }

  /// Normalizes the passed URI.
  static String normalizeURI(String uri) {
    if (uri.startsWith(_kAssetScheme)) {
      // Handle asset:// scheme. Only for Flutter.
      final key = encodeAssetKey(uri);
      return key;
    }
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

  @override
  String toString() =>
      'Media($uri, extras: $extras, httpHeaders: $httpHeaders)';

  /// URI scheme used to identify Flutter assets.
  static const String _kAssetScheme = 'asset://';

  /// Previously created [Media] instances.
  /// This [HashMap] is used to retrieve previously set [extras] & [httpHeaders].
  static final HashMap<String, _MediaCache> cache =
      HashMap<String, _MediaCache>();

  /// Previously created [Media] instances' reference count.
  static final HashMap<String, int> ref = HashMap<String, int>();
}

/// {@template _media_cache}
/// A simple class to pack optional arguments in [Media] together.
/// {@endtemplate}
class _MediaCache {
  /// Additional optional user data.
  ///
  /// Default: `null`.
  final Map<String, dynamic>? extras;

  /// HTTP headers.
  ///
  /// Default: `null`.
  final Map<String, String>? httpHeaders;

  /// {@macro _media_cache}
  const _MediaCache({
    this.extras,
    this.httpHeaders,
  });

  @override
  String toString() => '_MediaCache('
      'extras: $extras, '
      'httpHeaders: $httpHeaders'
      ')';
}
