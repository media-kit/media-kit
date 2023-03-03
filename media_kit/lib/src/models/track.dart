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

}

const String trackIdNo = "no";
const String trackIdAuto = "auto";