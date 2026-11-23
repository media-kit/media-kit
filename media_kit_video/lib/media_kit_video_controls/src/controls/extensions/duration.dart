// This file is a part of media_kit (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Extension methods for [Duration].
extension DurationExtension on Duration {
  /// Returns clamp of [Duration] between [min] and [max].
  Duration clamp(Duration min, Duration max) {
    if (this < min) {
      return min;
    }
    if (this > max) {
      return max;
    }
    return this;
  }

  /// Returns a [String] representation of [Duration].
  String label({Duration? reference}) {
    final Duration absoluteReference = (reference ?? this).abs();

    if (isNegative) {
      return abs().label(reference: absoluteReference);
    }

    if (absoluteReference > const Duration(days: 1)) {
      final String days = inDays.toString().padLeft(3, '0');
      final String hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final String minutes =
          (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final String seconds =
          (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (absoluteReference > const Duration(hours: 1)) {
      final String hours = inHours.toString().padLeft(2, '0');
      final String minutes =
          (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final String seconds =
          (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final String minutes = inMinutes.toString().padLeft(2, '0');
      final String seconds =
          (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }
}
