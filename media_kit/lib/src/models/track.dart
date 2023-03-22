import 'package:media_kit/src/models/track_type.dart';

/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright (c) 2021 & onwards, Domingo Montesdeoca González <DomingoMG97@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// {@template track}
///
/// Track
/// -----------
///
/// Represents a track which may be used for output in [Player].
///
/// {@endtemplate}
class Track {
  /// Type.
  final TrackType type;

  /// Id.
  final String id;

  /// Title.
  final String? title;

  /// Lang.
  final String? lang;

  /// {@macro track}
  Track(this.type, this.id, this.title, this.lang);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          title == other.title &&
          lang == other.lang;

  @override
  int get hashCode =>
      type.hashCode ^ id.hashCode ^ title.hashCode ^ lang.hashCode;

  @override
  String toString() {
    return 'Track{type: $type, id: $id, title: $title, lang: $lang}';
  }
}

const String trackIdNo = "no";
const String trackIdAuto = "auto";
