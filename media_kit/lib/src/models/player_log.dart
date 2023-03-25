/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// A log message sent by the libmpv backend.
class PlayerLog {
  /// The sender of the message.
  final String prefix;

  /// The log level.
  final String level;

  /// The log message.
  final String text;

  const PlayerLog({
    required this.prefix,
    required this.level,
    required this.text,
  });

  @override
  String toString() => 'PlayerLog(prefix: $prefix, level: $level, text: $text)';
}
