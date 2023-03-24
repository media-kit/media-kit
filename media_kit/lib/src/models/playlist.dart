/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/media.dart';

/// A [Playlist] represents a list of [Media]s & currently playing [index].
class Playlist {
  /// Currently opened [List] of [Media]s.
  final List<Media> medias;

  /// Currently playing [index].
  final int index;

  const Playlist(
    this.medias, {
    this.index = 0,
  });

  @override
  String toString() => 'Playlist(index: $index, medias: $medias)';

  Playlist copyWith({
    List<Media>? medias,
    int? index,
  }) {
    return Playlist(
      medias ?? this.medias,
      index: index ?? this.index,
    );
  }
}
