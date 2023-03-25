/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// {@template _track}
///
/// Track
/// -----
///
/// A video, audio or subtitle track available in [Media].
/// This may be selected for output in [Player].
///
/// {@endtemplate}
abstract class _Track {
  final String id;
  final String? title;
  final String? language;

  /// {@macro _track}
  const _Track(this.id, this.title, this.language);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (this is VideoTrack && other is VideoTrack) return id == other.id;
    if (this is AudioTrack && other is AudioTrack) return id == other.id;
    if (this is SubtitleTrack && other is SubtitleTrack) return id == other.id;
    return false;
  }

  @override
  int get hashCode {
    if (this is VideoTrack) return 0x1 ^ id.hashCode;
    if (this is AudioTrack) return 0x2 ^ id.hashCode;
    if (this is SubtitleTrack) return 0x3 ^ id.hashCode;
    return 0x0;
  }

  @override
  String toString() => 'Track($id, $title, $language)';
}

/// {@template video_track}
/// A video available in [Media].
/// This may be selected for output in [Player].
/// {@endtemplate}
class VideoTrack extends _Track {
  /// {@macro video_track}
  const VideoTrack(super.id, super.title, super.language);

  /// No video track. Disables video output.
  factory VideoTrack.no() => VideoTrack('no', null, null);

  /// Default video track. Selects the first video track.
  factory VideoTrack.auto() => VideoTrack('auto', null, null);

  @override
  String toString() => 'VideoTrack($id, $title, $language)';
}

/// {@template audio_track}
/// An audio available in [Media].
/// This may be selected for output in [Player].
/// {@endtemplate}
class AudioTrack extends _Track {
  /// {@macro audio_track}
  const AudioTrack(super.id, super.title, super.language);

  /// No audio track. Disables audio output.
  factory AudioTrack.no() => AudioTrack('no', null, null);

  /// Default audio track. Selects the first audio track.
  factory AudioTrack.auto() => AudioTrack('auto', null, null);

  @override
  String toString() => 'AudioTrack($id, $title, $language)';
}

/// {@template subtitle_track}
/// A subtitle available in [Media].
/// This may be selected for output in [Player].
/// {@endtemplate}
class SubtitleTrack extends _Track {
  /// {@macro subtitle_track}
  const SubtitleTrack(super.id, super.title, super.language);

  /// No subtitle track. Disables subtitle output.
  factory SubtitleTrack.no() => SubtitleTrack('no', null, null);

  /// Default subtitle track. Selects the first subtitle track.
  factory SubtitleTrack.auto() => SubtitleTrack('auto', null, null);

  @override
  String toString() => 'SubtitleTrack($id, $title, $language)';
}

// For composition in [PlayerState] & [PlayerStreams] classes.

/// {@template track}
/// Currently selected tracks.
/// {@endtemplate}
class Track {
  /// Currently selected video track.
  final VideoTrack video;

  /// Currently selected audio track.
  final AudioTrack audio;

  /// Currently selected subtitle track.
  final SubtitleTrack subtitle;

  /// {@macro track}
  const Track({
    this.video = const VideoTrack('auto', null, null),
    this.audio = const AudioTrack('auto', null, null),
    this.subtitle = const SubtitleTrack('auto', null, null),
  });

  Track copyWith({
    VideoTrack? video,
    AudioTrack? audio,
    SubtitleTrack? subtitle,
  }) {
    return Track(
      video: video ?? this.video,
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  String toString() =>
      'Track(video: $video, audio: $audio, subtitle: $subtitle)';
}

/// {@template tracks}
/// Currently available tracks.
/// {@endtemplate}
class Tracks {
  /// Currently available video tracks.
  final List<VideoTrack> video;

  /// Currently available audio tracks.
  final List<AudioTrack> audio;

  /// Currently available subtitle tracks.
  final List<SubtitleTrack> subtitle;

  /// {@macro tracks}
  const Tracks({
    this.video = const [VideoTrack('auto', null, null)],
    this.audio = const [AudioTrack('auto', null, null)],
    this.subtitle = const [SubtitleTrack('auto', null, null)],
  });

  @override
  String toString() =>
      'Tracks(video: $video, audio: $audio, subtitle: $subtitle)';
}
