/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:synchronized/synchronized.dart';

/// {@template lock_ext}
///
/// LockExt
/// -------
///
/// A [LockExt] is a wrapper around [Lock] to provide [count] which represents the number of tasks currently running.
///
/// {@endtemplate}
class LockExt {
  /// The underlying [Lock] instance.
  final Lock instance = Lock();

  /// Executes [computation] when lock is available.
  ///
  /// Only one asynchronous block can run while the lock is retained.
  ///
  /// If [timeout] is specified, it will try to grab the lock and will not
  /// call the computation callback and throw a [TimeoutExpection] is the lock
  /// cannot be grabbed in the given duration.
  Future<T> synchronized<T>(
    Future<T> Function() computation, {
    Duration? timeout,
  }) async {
    count++;
    try {
      return instance.synchronized<T>(
        computation,
        timeout: timeout,
      );
    } finally {
      count--;
      if (count == 0) {
        time = DateTime.now();
      }
    }
  }

  /// The number of tasks currently running.
  int count = 0;

  /// Last time when [count] was 0.
  DateTime time = DateTime.now();
}
