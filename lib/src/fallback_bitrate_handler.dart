/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:safe_local_storage/safe_local_storage.dart';

/// libmpv doesn't seem to read the bitrate from the files which contain bitrate in their stream metadata (not file metadata).
/// Typically, I've seen this happening with FLAC & OGG files, since they do not offer the bitrate as a metadata / attached-tags key.
///
/// Adding this helper class to calculate the bitrate of the FLAC & OGG files manually.
/// Considering FLAC is a lossless format, this approximation should be fine.
/// At-least better than the one in libmpv, because it calculates the bitrate from the loaded stream currently in-memory & updates it dynamically as playback progresses.
abstract class FallbackBitrateHandler {
  static bool isLocalFLACOrOGGFile(String uri) =>
      extractLocalFLACorOGGFilePath(uri) != null;

  static String? extractLocalFLACorOGGFilePath(String uri) {
    try {
      final resource = Uri.parse(uri);
      // Handle file:// URIs.
      if (resource.isScheme('FILE')) {
        if (resource.toFilePath().toUpperCase().endsWith('.FLAC') ||
            resource.toFilePath().toUpperCase().endsWith('.OGG')) {
          return resource.toFilePath();
        }
      }
      // Handle local file paths.
      if (!(resource.isScheme('HTTP') ||
          resource.isScheme('HTTPS') ||
          resource.isScheme('FTP') ||
          resource.isScheme('RSTP'))) {
        if (resource.toString().toUpperCase().endsWith('.FLAC') ||
            resource.toString().toUpperCase().endsWith('.OGG')) {
          return uri;
        }
      }
      // No support for other URIs.
      return null;
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
      return null;
    }
  }

  static Future<double> calculateBitrate(String uri, Duration duration) async {
    try {
      final resource = extractLocalFLACorOGGFilePath(uri);
      if (resource != null) {
        final file = File(resource);
        final size = await file.size_();
        final result = size * 8 / duration.inSeconds;
        print('FLAC/OGG birate correction: ${result / 1e3} kb/s');
        return result;
      }
      return 0;
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
      return 0;
    }
  }
}
