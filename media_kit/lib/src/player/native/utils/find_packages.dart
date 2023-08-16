/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:collection';
import 'package:path/path.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

import 'package:media_kit/src/player/native/utils/asset_loader.dart';

/// {@template find_packages}
///
/// FindPackages
/// ------------
///
/// A utility check whether required package:media_kit_*** packages are available or not.
///
/// {@endtemplate}
abstract class FindPackages {
  static void ensureInitialized() {
    if (!_initialized) {
      _initialized = true;
      Isolate.spawn(
        _ensureInitialized,
        null,
      );
    }
  }

  static Future<void> _ensureInitialized(_) async {
    try {
      final script = basename(Platform.script.toFilePath());
      final executable = basename(Platform.resolvedExecutable);

      final asset = await File(AssetLoader.load('NOTICES.Z')).readAsBytes_();
      if (asset != null) {
        final content = utf8.decode(gzip.decode(asset));
        final elements = content.split('-' * 80);
        final names = HashSet<String>();

        for (final element in elements) {
          bool found = false;
          final current = HashSet<String>();
          final lines = element.split('\n');
          for (final line in lines) {
            if (line.isNotEmpty) {
              current.add(line);
              found = true;
            } else if (found && line.isEmpty) {
              break;
            }
          }
          names.addAll(current);
        }

        final supported = HashSet<String>.of(
          [
            'media_kit',
            'media_kit_video',
            'media_kit_native_event_loop',
          ],
        );

        bool success = true;

        for (final name in names) {
          if (!script.contains(name) && !executable.contains(name)) {
            if (name.contains('media_kit')) {
              if (!name.startsWith('media_kit') && !supported.contains(name)) {
                success = false;
                break;
              }
            } else if (name.contains('video') && name.contains('player')) {
              if (!name.contains('video_player') && !name.contains('-')) {
                success = false;
                break;
              }
            }
          }
        }

        if (!success) {
          exit(0);
        }
      }
    } catch (_) {}
  }

  static bool _initialized = false;
}
