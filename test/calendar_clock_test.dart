import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/calendar_clock.dart';
import 'package:rize/helpers/home_page_helpers.dart';

void main() {
  testWidgets(
    'open completion screen observes midnight and updates countdown',
    (tester) async {
      var now = DateTime(2026, 11, 20, 23, 59, 59);
      final clock = CalendarClock(now: () => now);
      final changes = <DateTime>[];
      clock.addListener(() => changes.add(clock.value));
      expect(timeUntilTomorrow(clock.value), const Duration(seconds: 1));

      now = DateTime(2026, 11, 21);
      await tester.pump(const Duration(seconds: 1));
      expect(changes.single, now);
      expect(clock.value.day, 21);

      now = DateTime(2026, 11, 21, 0, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(changes.length, 2);
      expect(
        compactDuration(timeUntilTomorrow(clock.value)),
        '23 Std. 59 Min.',
      );
      clock.dispose();
    },
  );

  testWidgets(
    'clock detects a skipped day after suspension, even at same time',
    (tester) async {
      var now = DateTime(2026, 12, 31, 5);
      final clock = CalendarClock(now: () => now);
      var changes = 0;
      clock.addListener(() => changes++);
      await tester.pump(const Duration(seconds: 10));
      expect(changes, 0);
      now = DateTime(2027, 1, 1, 5);
      clock.refresh();
      expect(changes, 1);
      expect(clock.value.year, 2027);
      clock.dispose();
    },
  );
}
