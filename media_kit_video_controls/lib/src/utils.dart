/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Return [Duration] [value] as typical formatted string.
String formatDuration(Duration value, Duration reference) {
  if (reference > const Duration(days: 1)) {
    final days = value.inDays.toString().padLeft(3, '0');
    final hours =
        (value.inHours - (value.inDays * 24)).toString().padLeft(2, '0');
    final minutes =
        (value.inMinutes - (value.inHours * 60)).toString().padLeft(2, '0');
    final seconds =
        (value.inSeconds - (value.inMinutes * 60)).toString().padLeft(2, '0');
    return '$days:$hours:$minutes:$seconds';
  } else if (reference > const Duration(hours: 1)) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes =
        (value.inMinutes - (value.inHours * 60)).toString().padLeft(2, '0');
    final seconds =
        (value.inSeconds - (value.inMinutes * 60)).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  } else {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (value.inSeconds - (value.inMinutes * 60)).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
