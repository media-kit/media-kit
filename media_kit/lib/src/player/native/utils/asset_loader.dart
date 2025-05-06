/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:safe_local_storage/safe_local_storage.dart';

import 'package:media_kit/src/player/native/utils/android_asset_loader.dart';

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
    return asset;
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
    // https://github.com/media-kit/media-kit/issues/121
    return uri
        .substring(startIdx)
        .splitMapJoin('/', onNonMatch: Uri.encodeComponent);
  }

  /// URI scheme used to identify Flutter assets.
  static const String _kAssetScheme = 'asset://';
}
