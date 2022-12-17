/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:media_kit/src/models/media.dart';

/// A [Playlist] collectively representing currently playing [index]
/// & a [List] of opened [Media]s inside the [Player].
class Playlist {
  /// Currently playing [index].
  int index;

  /// Currently opened [List] of [Media]s.
  List<Media> medias;

  Playlist(
    this.medias, {
    this.index = 0,
  });

  @override
  String toString() => 'Playlist(index: $index, medias: $medias)';
}
