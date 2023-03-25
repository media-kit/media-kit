/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// An error experienced by [Player] during playback.
class PlayerError {
  /// Error code.
  final int code;

  /// Error message.
  final String message;

  const PlayerError(
    this.code,
    this.message,
  );

  @override
  String toString() => 'PlayerError(code: $code, message: $message)';
}
