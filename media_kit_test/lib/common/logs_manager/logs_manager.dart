import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum LogType {
  info,
  error,
}

class LogsManager {
  final List<MapEntry<LogType, String>> _logs = [];

  // Adds an info log
  void addInfoLog(String message) {
    _addLog(LogType.info, message);
  }

  // Adds an error log
  void addErrorLog(String message) {
    _addLog(LogType.error, message);
  }

  // Private method to add a log with a given type
  void _addLog(LogType type, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = "$timestamp [${type.name.toUpperCase()}] $message";
    _logs.add(MapEntry(type, logEntry));
    debugPrint(logEntry); // Optionally print the log
  }

  // Retrieves logs as a single string, filtered by type if specified
  String getAllLogsAsString({LogType? type}) {
    return _logs
        .where((entry) => type == null || entry.key == type)
        .map((entry) => entry.value)
        .join('\n');
  }


  // Copy logs to clipboard, filtered by type if specified
  void copyLogs({LogType? type}) {
    final logsString = getAllLogsAsString(type: type);
    Clipboard.setData(ClipboardData(text: logsString));
  }
}
