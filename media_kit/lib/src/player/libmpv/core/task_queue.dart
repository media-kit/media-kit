/// This file is a part of media_kit (https://github.com/alexmercerind/media_kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';

/// TaskQueue
/// ---------
///
/// A simple class where multiple tasks can be queued for sequential execution with specified refractory duration between each task.
class TaskQueue {
  /// [TaskQueue] singleton instance.
  static final instance = TaskQueue._(const Duration(seconds: 10));

  /// The refractory duration between each task's execution.
  final Duration refractoryDuration;

  TaskQueue._(this.refractoryDuration);

  /// Adds a task to the queue for execution.
  void add(Function task) {
    _tasks.add(task);
    if (!_running) {
      _running = true;
      _run();
    }
  }

  Future<void> _run() async {
    while (_tasks.isNotEmpty) {
      final task = _tasks.removeAt(0);
      await Future.delayed(refractoryDuration);
      await task();
    }
    _running = false;
  }

  bool _running = false;
  final List<Function> _tasks = [];
}
