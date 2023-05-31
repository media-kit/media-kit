/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:media_kit/src/models/playable.dart';
import 'package:media_kit/src/models/media/media.dart';

/// {@template playlist}
///
/// Playlist
/// --------
///
/// A [Playlist] represents a list of [Media]s & currently playing [index].
/// This may be opened in [Player] for playback.
///
/// ```dart
/// final playable = Playlist(
///   [
///     Media('file:///C:/Users/Hitesh/Music/Sample.mp3'),
///     Media('file:///C:/Users/Hitesh/Video/Sample.mkv'),
///     Media('https://www.example.com/sample.mp4'),
///     Media('rtsp://www.example.com/live'),
///   ],
/// );
/// ```
///
/// {@endtemplate}
class Playlist extends Playable {
  /// Currently opened [List] of [Media]s.
  final List<Media> medias;

  /// Currently playing [index].
  final int index;

  /// {@macro playlist}
  const Playlist(
    this.medias, {
    this.index = 0,
  });

  Playlist copyWith({
    List<Media>? medias,
    int? index,
  }) {
    return Playlist(
      medias ?? this.medias,
      index: index ?? this.index,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          ListEquality().equals(medias, other.medias) &&
          index == other.index;

  @override
  // TODO: implement hashCode
  int get hashCode => medias.hashCode ^ index.hashCode;

  @override
  String toString() => 'Playlist(medias: $medias, index: $index)';
}
