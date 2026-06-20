import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/types/workout.dart';
import 'date_helpers.dart';
import 'progress_statistics.dart';
import 'value_parsing_helpers.dart';

List<WorkoutDayEntry> parseWorkoutHistory(
  Iterable<QueryDocumentSnapshot<Map<String, Object?>>> documents,
) {
  final List<WorkoutDayEntry> entries = <WorkoutDayEntry>[];

  for (final QueryDocumentSnapshot<Map<String, Object?>> document
      in documents) {
    final Map<String, Object?> data = document.data();
    final Object? scheduledAt = data['scheduledAt'];
    final DateTime? date = scheduledAt is Timestamp
        ? normalizeDate(scheduledAt.toDate())
        : (data['dayKey'] is String
              ? tryParseDateKey(data['dayKey']! as String)
              : tryParseDateKey(document.id));
    if (date == null) continue;

    try {
      entries.add(
        WorkoutDayEntry(
          date: date,
          workout: ScheduledWorkout.fromJson(toDynamicMap(data)),
        ),
      );
    } on Object {
      // Ignore malformed legacy records rather than breaking the entire page.
    }
  }

  entries.sort(
    (WorkoutDayEntry a, WorkoutDayEntry b) => a.date.compareTo(b.date),
  );
  return entries;
}

Map<DateTime, double> parseScoreHistory(
  Iterable<QueryDocumentSnapshot<Map<String, Object?>>> documents,
) {
  final Map<DateTime, _ScoreRecord> latestByDay = <DateTime, _ScoreRecord>{};

  for (final QueryDocumentSnapshot<Map<String, Object?>> document
      in documents) {
    final Map<String, Object?> data = document.data();
    final Timestamp? timestamp = data['ts'] is Timestamp
        ? data['ts'] as Timestamp
        : null;

    DateTime? day;
    final Object? workoutId = data['workoutId'];
    if (workoutId is String) day = tryParseDateKey(workoutId);
    day ??= timestamp == null ? null : normalizeDate(timestamp.toDate());

    final double? score = asDouble(data['newScore']);
    if (day == null || score == null) continue;

    final DateTime normalizedDay = normalizeDate(day);
    final _ScoreRecord candidate = _ScoreRecord(
      value: score,
      timestamp: timestamp?.toDate(),
    );
    final _ScoreRecord? existing = latestByDay[normalizedDay];

    if (existing == null || candidate.isNewerThan(existing)) {
      latestByDay[normalizedDay] = candidate;
    }
  }

  return latestByDay.map<DateTime, double>(
    (DateTime day, _ScoreRecord record) =>
        MapEntry<DateTime, double>(day, record.value),
  );
}

class _ScoreRecord {
  const _ScoreRecord({required this.value, required this.timestamp});

  final double value;
  final DateTime? timestamp;

  bool isNewerThan(_ScoreRecord other) {
    if (timestamp == null) return other.timestamp == null;
    if (other.timestamp == null) return true;
    return timestamp!.isAfter(other.timestamp!);
  }
}
