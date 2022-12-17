/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:media_kit/src/models/media.dart';
import 'package:meta/meta.dart';

import 'package:media_kit/src/models/tagger_metadata.dart';

/// {@template tagger_configuration}
///
/// TaggerConfiguration
/// -------------------
/// Configurable options for customizing the [Tagger] behavior.
///
/// {@endtemplate}
class TaggerConfiguration {
  /// Decides whether duration & bitrate of the media should be queried.
  /// Disabling [verbose] parsing can give some massive performance benefits, especially when reading metadata of large number of media files.
  ///
  /// Default: `false`.
  /// Platforms: Windows, Linux.
  final bool verbose;

  /// Sets manually specified location to the libmpv shared library & overrides the default look-up behavior.
  ///
  /// Default: `null`.
  /// Platforms: Windows, Linux.
  final String? libmpv;

  /// Optional callback invoked when the internals of the [Player] are configured & ready for playback.
  ///
  /// Default: `null`.
  /// Platforms: Windows, Linux.
  final void Function()? ready;

  /// {@macro tagger_configuration}
  const TaggerConfiguration({
    this.verbose = false,
    this.libmpv,
    this.ready,
  });
}

/// {@template platform_tagger}
/// PlatformPlayer
/// --------------
///
/// This class provides the interface for platform specific tagger implementations.
/// The platform specific implementations are expected to implement the methods accordingly.
///
/// The subclasses are then used in composition with the [Tagger] class, based on the platform the application is running on.
///
/// {@endtemplate}
abstract class PlatformTagger {
  /// {@macro platform_tagger}
  PlatformTagger({required this.configuration});

  /// User defined configuration for [Tagger].
  final TaggerConfiguration configuration;

  FutureOr<void> dispose({int code = 0}) async {}

  FutureOr<TaggerMetadata> parse(
    Media media, {
    File? cover,
    Directory? coverDirectory,
    bool waitUntilCoverIsSaved = false,
    Duration timeout = const Duration(seconds: 5),
  }) {
    throw UnimplementedError(
      '[PlatformPlayer.parse] is not implemented.',
    );
  }

  /// Deserializes the platform specific metadata into [TaggerMetadata] instance.
  @protected
  TaggerMetadata serialize(dynamic json) {
    throw UnimplementedError(
      '[PlatformPlayer.deserialize] is not implemented.',
    );
  }

  /// Extracts individual artists from the artist tag [String] value & returns [List<String>].
  @protected
  List<String>? splitArtistTag(String? tag) {
    if (tag == null) return null;

    final exempted = <String>[];
    for (final exception in kArtistNamesHavingSeparators) {
      if (tag.contains(exception)) {
        exempted.add(exception);
      }
    }
    for (final element in kArtistNamesHavingSeparators) {
      tag = tag!.replaceAll(element, '');
    }
    final artists = tag!
        .split(RegExp(r';|//|/|\\|\|'))
        .map((e) => e.trim())
        .toList()
        .toSet()
        .toList()
      ..removeWhere((element) => element.isEmpty);
    return artists + exempted;
  }

  /// Extracts the year from possible formats of date or year tag [String] value & returns [String].
  @protected
  String? splitDateTag(String? date) {
    if (date == null) return null;
    return date.split(RegExp(r'[.\-/]')).first.trim();
  }

  /// Parses the given [value] into [int] & returns it.
  @protected
  int? parseInteger(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        try {
          return int.parse(value);
        } catch (exception) {
          return int.parse(value.split('/').first);
        }
      } catch (exception) {
        // Do nothing.
      }
    }
    return null;
  }

  /// Checks if the given [value] is `null` or an empty [String].
  @protected
  bool isNullOrEmpty(dynamic value) => [null, ''].contains(value);
}

// Some special artist names that are handled separately because they include `;`, `//`, `/`, `\\` or `\` in their name.

const kArtistNamesHavingSeparators = {
  'AC/DC',
  'Au/Ra',
  'Axwell /\\ Ingrosso',
};
