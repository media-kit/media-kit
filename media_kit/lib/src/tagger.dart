/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:async';

import 'package:media_kit/src/models/media.dart';
import 'package:media_kit/src/platform_tagger.dart';
import 'package:media_kit/src/libmpv/tagger.dart' as libmpv;

import 'package:media_kit/src/models/tagger_metadata.dart';

/// {@template tagger}
///
/// Tagger
/// ------
///
/// [Tagger] class provides high-level interface for retrieving metadata tags from a [Media].
/// Call [dispose] to free the allocated resources back to the system.
///
/// **NOTE**: Changes to this API may be made without any prior notice.
///
/// ```dart
/// final tagger = Tagger();
/// final metadata = await tagger.parse(
///   Media('https://alexmercerind.github.io/music.m4a'),
///   cover: File('cover.jpg'),
/// );
/// ```
///
/// {@endtemplate}
class Tagger {
  /// {@macro tagger}
  Tagger({
    TaggerConfiguration configuration = const TaggerConfiguration(),
  }) {
    if (Platform.isWindows) {
      platform = libmpv.Tagger(configuration: configuration);
    }
    if (Platform.isLinux) {
      platform = libmpv.Tagger(configuration: configuration);
    }
    if (platform == null) {
      // TODO: Implement other platforms.
      throw UnimplementedError(
        'No [Tagger] implementation found for ${Platform.operatingSystem}.',
      );
    }
  }

  /// Platform specific internal implementation initialized depending upon the current platform.
  PlatformTagger? platform;

  /// Disposes the [Tagger] instance & releases the resources.
  FutureOr<void> dispose({int code = 0}) {
    return platform?.dispose(code: code);
  }

  /// Parses a [Media] & returns its metadata.
  ///
  /// Optionally, following argument may be passed:
  ///
  /// * [cover] may be passed to save the cover art of the [Media] to the location.
  /// * [coverDirectory] may be passed to save the cover art of the [Media] to the directory.
  /// * [waitUntilCoverIsSaved] may be passed to wait until the cover art is saved.
  /// * [timeout] may be passed to set the timeout duration for the parsing operation.
  ///
  /// Throws [FormatException] if an invalid, corrupt or inexistent [Media] is passed.
  ///
  FutureOr<TaggerMetadata> parse(
    Media media, {
    File? cover,
    Directory? coverDirectory,
    bool waitUntilCoverIsSaved = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    final result = platform?.parse(
      media,
      cover: cover,
      coverDirectory: coverDirectory,
      waitUntilCoverIsSaved: waitUntilCoverIsSaved,
      timeout: timeout,
    );
    return result!;
  }
}
