import 'package:wakelock_plus/wakelock_plus.dart';

/// Manage the wakelock behavior for multiple instances.
class Wakelock {
  static final Set<Wakelock> _enabledInstances = {};
  static bool _wakelockEnabled = false;

  /// Marks the wakelock as enabled for this instance.
  void enable() {
    _enabledInstances.add(this);
    _updateWakeLock();
  }

  /// Marks the wakelock as disabled for this instance.
  void disable() {
    _enabledInstances.remove(this);
    _updateWakeLock();
  }

  /// Toggles the wakelock status for this instance.
  void toggle() {
    if (_enabledInstances.contains(this)) {
      _enabledInstances.remove(this);
    } else {
      _enabledInstances.add(this);
    }
    _updateWakeLock();
  }

  /// Updates the upstream wakelock status based on the enabled instances count.
  static void _updateWakeLock() {
    if (_enabledInstances.isNotEmpty && !_wakelockEnabled) {
      WakelockPlus.enable().catchError((_) {});
      _wakelockEnabled = true;
    } else if (_enabledInstances.isEmpty && _wakelockEnabled) {
      WakelockPlus.disable().catchError((_) {});
      _wakelockEnabled = false;
    }

    print("### wakelock: ${_enabledInstances.length}, $_wakelockEnabled");
  }
}
