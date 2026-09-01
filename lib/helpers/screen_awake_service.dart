import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

class ScreenAwakeHandle {
  static final Set<ScreenAwakeHandle> _activeHandles = <ScreenAwakeHandle>{};

  bool _active = false;
  bool _disposed = false;

  Future<void> setActive(bool active) async {
    if (_disposed || _active == active) return;
    _active = active;
    if (active) {
      _activeHandles.add(this);
    } else {
      _activeHandles.remove(this);
    }
    await _syncWakelock();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_active) {
      _active = false;
      _activeHandles.remove(this);
      unawaited(_syncWakelock());
    }
  }

  static Future<void> _syncWakelock() {
    return _activeHandles.isEmpty
        ? WakelockPlus.disable()
        : WakelockPlus.enable();
  }
}
