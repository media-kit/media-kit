/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// {@template tagger_metadata}
///
/// TaggerMetadata
/// --------------
///
/// Embedded metadata & tags of a media file (specifically music file).
///
/// **NOTE**: Changes to this API may be made without any prior notice.
///
/// This implementation is used in [Harmonoid](https://github.com/harmonoid/harmonoid).
/// Thus, focused on music specific metadata & tags.
///
/// {@endtemplate}
class TaggerMetadata {
  /// URI.
  final Uri uri;

  /// Track name.
  /// Defaults to the name of the [File] or [Uri]'s last segment if not present.
  final String trackName;

  /// Album name.
  final String? albumName;

  /// Track number.
  final int? trackNumber;

  /// Disc number.
  final int? discNumber;

  /// Album length.
  final int? albumLength;

  /// Album artist.
  final String? albumArtistName;

  /// Track artists.
  final List<String>? trackArtistNames;

  /// Author.
  final String? authorName;

  /// Writer.
  final String? writerName;

  /// Year of release.
  final String? year;

  /// Genre.
  // TODO(@alexmercerind): Should be [List<String>]. Implement splitting of multiple genres.
  final String? genre;

  /// Lyrics.
  final String? lyrics;

  /// [DateTime] when the track was saved on the device.
  /// Defaults to [DateTime.now] for non-[File] [Uri]s or in case of error.
  final DateTime timeAdded;

  /// [Duration] of the track.
  /// Defaults to `null` if not present or requested.
  final Duration? duration;

  /// Bitrate of the track.
  /// Defaults to `null` if not present or requested.
  final int? bitrate;

  /// Platform specific non-serialized data.
  final dynamic data;

  /// {@macro tagger_metadata}
  TaggerMetadata({
    required this.uri,
    required this.trackName,
    required this.albumName,
    required this.trackNumber,
    required this.discNumber,
    required this.albumLength,
    required this.albumArtistName,
    required this.trackArtistNames,
    required this.authorName,
    required this.writerName,
    required this.year,
    required this.genre,
    required this.lyrics,
    required this.timeAdded,
    required this.duration,
    required this.bitrate,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'uri': uri.toString(),
      'trackName': trackName,
      'albumName': albumName,
      'trackNumber': trackNumber,
      'discNumber': discNumber,
      'albumLength': albumLength,
      'albumArtistName': albumArtistName,
      'trackArtistNames': trackArtistNames,
      'authorName': authorName,
      'writerName': writerName,
      'year': year,
      'genre': genre,
      'lyrics': lyrics,
      'timeAdded': timeAdded.millisecondsSinceEpoch,
      'duration': duration?.inMilliseconds,
      'bitrate': bitrate,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'TaggerMetadata(uri: $uri, trackName: $trackName, albumName: $albumName, trackNumber: $trackNumber, discNumber: $discNumber, albumLength: $albumLength, albumArtistName: $albumArtistName, trackArtistNames: $trackArtistNames, authorName: $authorName, writerName: $writerName, year: $year, genre: $genre, lyrics: $lyrics, timeAdded: $timeAdded, duration: $duration, bitrate: $bitrate, data: $data)';
  }
}
