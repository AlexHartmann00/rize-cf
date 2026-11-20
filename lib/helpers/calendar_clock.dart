import 'dart:async';

import 'package:flutter/foundation.dart';

/// Rechecks wall time so midnight and app suspension do not leave yesterday's UI.
class CalendarClock extends ValueNotifier<DateTime> {
  CalendarClock({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super((now ?? DateTime.now)()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }

  final DateTime Function() _now;
  late final Timer _timer;

  void refresh() {
    final current = _now();
    final previous = value;
    if (current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day ||
        current.hour != previous.hour ||
        current.minute != previous.minute) {
      value = current;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
