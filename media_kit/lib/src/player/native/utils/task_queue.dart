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
///
class TaskQueue {
  /// [TaskQueue] singleton instance.
  static final instance = TaskQueue._(const Duration(seconds: 10));

  /// The refractory duration between each task's execution.
  final Duration refractoryDuration;

  TaskQueue._(this.refractoryDuration) {
    _timer = Timer.periodic(refractoryDuration, _execute);
  }

  /// Adds a task to the queue for execution. The task will be removed from the queue when it returns `true`.
  void add(bool Function() task) {
    _tasks.add(task);
  }

  /// Executes all the tasks in the queue sequentially.
  void _execute(Timer timer) {
    if (_tasks.isNotEmpty) {
      final task = _tasks[0];
      if (task.call()) {
        _tasks.removeAt(0);
      }
    }
  }

  /// Disposes the [TaskQueue] instance.
  void dispose() {
    _timer?.cancel();
  }

  Timer? _timer;
  final List<Function> _tasks = [];
}
