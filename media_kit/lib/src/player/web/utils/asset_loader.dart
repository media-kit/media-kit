/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'package:media_kit/src/values.dart';

/// {@template asset_loader}
///
/// AssetLoader
/// -----------
///
/// A utility to load Flutter assets.
///
/// {@endtemplate}
class AssetLoader {
  static String load(String uri) {
    return encodeAssetKey(uri);
  }

  static String encodeAssetKey(String uri) {
    var startIdx = 0;
    // ignore scheme case
    if (_kAssetScheme ==
        uri
            .substring(0, _kAssetScheme.length.clamp(0, uri.length))
            .toLowerCase()) {
      startIdx += _kAssetScheme.length;
    }
    if (uri[startIdx] == '/') {
      startIdx++;
    }
    final key = uri.substring(startIdx);

    // https://github.com/media-kit/media-kit/issues/531
    // https://github.com/media-kit/media-kit/issues/121
    if (kReleaseMode) {
      return 'assets/${key.splitMapJoin('/', onNonMatch: (e) => Uri.encodeComponent(Uri.encodeComponent(e)))}';
    }
    return key.splitMapJoin('/', onNonMatch: Uri.encodeComponent);
  }

  /// URI scheme used to identify Flutter assets.
  static const String _kAssetScheme = 'asset://';
}
