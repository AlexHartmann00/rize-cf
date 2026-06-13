DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? tryParseDateKey(String value) {
  final String input = value.trim();

  final RegExp dashed = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final RegExpMatch? dashedMatch = dashed.firstMatch(input);
  if (dashedMatch != null) {
    return _safeDate(
      int.parse(dashedMatch.group(1)!),
      int.parse(dashedMatch.group(2)!),
      int.parse(dashedMatch.group(3)!),
    );
  }

  final RegExp compact = RegExp(r'^(\d{4})(\d{2})(\d{2})$');
  final RegExpMatch? compactMatch = compact.firstMatch(input);
  if (compactMatch != null) {
    return _safeDate(
      int.parse(compactMatch.group(1)!),
      int.parse(compactMatch.group(2)!),
      int.parse(compactMatch.group(3)!),
    );
  }

  return null;
}

DateTime? _safeDate(int year, int month, int day) {
  final DateTime result = DateTime(year, month, day);
  if (result.year != year || result.month != month || result.day != day) {
    return null;
  }
  return result;
}

Iterable<DateTime> daysEndingAt(DateTime end, {int count = 30}) sync* {
  assert(count > 0);
  final DateTime normalizedEnd = normalizeDate(end);
  final DateTime start = normalizedEnd.subtract(Duration(days: count - 1));

  for (int index = 0; index < count; index++) {
    yield start.add(Duration(days: index));
  }
}

Set<int> activeDayNumbersForMonth(
  Set<DateTime> activeDays,
  DateTime month,
) {
  return activeDays
      .where((DateTime date) =>
          date.year == month.year && date.month == month.month)
      .map((DateTime date) => date.day)
      .toSet();
}

int daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

int leadingCalendarCells(DateTime month) {
  final DateTime first = DateTime(month.year, month.month, 1);
  return first.weekday - DateTime.monday;
}
