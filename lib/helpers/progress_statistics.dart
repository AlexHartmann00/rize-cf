import 'package:flutter/foundation.dart';
import 'package:rize/types/workout.dart';
import 'date_helpers.dart';

@immutable
class WorkoutDayEntry {
  const WorkoutDayEntry({required this.date, required this.workout});

  final DateTime date;
  final ScheduledWorkout workout;
}

@immutable
class DayImpact {
  const DayImpact({required this.score, required this.impactLevel});

  final double score;
  final ImpactLevel impactLevel;
}

@immutable
class ProgressPoint {
  const ProgressPoint({
    required this.index,
    required this.date,
    required this.value,
  });

  final int index;
  final DateTime date;
  final double? value;
}

@immutable
class ProgressStatistics {
  const ProgressStatistics({
    required this.completedUnits,
    required this.dynamicRepetitions,
    required this.staticSeconds,
    required this.activeDays,
    required this.impactByDay,
    required this.lastImpact,
  });

  final int completedUnits;
  final int dynamicRepetitions;
  final int staticSeconds;
  final Set<DateTime> activeDays;
  final Map<DateTime, DayImpact> impactByDay;
  final DayImpact? lastImpact;

  factory ProgressStatistics.fromEntries(List<WorkoutDayEntry> entries) {
    int completedUnits = 0;
    int dynamicRepetitions = 0;
    int staticSeconds = 0;
    final Set<DateTime> activeDays = <DateTime>{};
    final Map<DateTime, DayImpact> impactByDay = <DateTime, DayImpact>{};
    DayImpact? lastImpact;

    final List<WorkoutDayEntry> sorted = List<WorkoutDayEntry>.of(
      entries,
    )..sort((WorkoutDayEntry a, WorkoutDayEntry b) => a.date.compareTo(b.date));

    for (final WorkoutDayEntry entry in sorted) {
      final ScheduledWorkout workout = entry.workout;
      final int completed = completedWorkoutUnits(workout.schedule);
      if (completed <= 0) continue;

      final DateTime day = normalizeDate(entry.date);
      activeDays.add(day);
      completedUnits += completed;

      if (workout.workoutType == WorkoutType.dynamic) {
        dynamicRepetitions += workout.schedule.fold<int>(
          0,
          (int sum, WorkoutStep step) =>
              sum +
              (step.actualValue ??
                  ((workout.baseReps ?? 0) *
                      workout.intensityFactor *
                      step.completedUnits)),
        );
      } else {
        staticSeconds += workout.schedule.fold<int>(
          0,
          (int sum, WorkoutStep step) =>
              sum +
              (step.actualValue ??
                  ((workout.baseSeconds ?? 0) *
                      workout.intensityFactor *
                      step.completedUnits)),
        );
      }

      final DayImpact previousImpact =
          impactByDay[day] ??
          const DayImpact(score: 0, impactLevel: ImpactLevel.low);
      final double combinedScore = (previousImpact.score + workout.impactScore)
          .clamp(0, 1);
      final DayImpact impact = DayImpact(
        score: combinedScore,
        impactLevel: workout.impactLevel,
      );
      impactByDay[day] = impact;
      lastImpact = impact;
    }

    return ProgressStatistics(
      completedUnits: completedUnits,
      dynamicRepetitions: dynamicRepetitions,
      staticSeconds: staticSeconds,
      activeDays: Set<DateTime>.unmodifiable(activeDays),
      impactByDay: Map<DateTime, DayImpact>.unmodifiable(impactByDay),
      lastImpact: lastImpact,
    );
  }
}

int completedWorkoutUnits(List<WorkoutStep> schedule) => schedule.fold<int>(
  0,
  (int total, WorkoutStep step) => total + step.completedUnits,
);

int currentStreak(Set<DateTime> activeDays, DateTime today) {
  if (activeDays.isEmpty) return 0;

  final Set<DateTime> normalized = activeDays
      .map<DateTime>(normalizeDate)
      .toSet();
  DateTime cursor = normalizeDate(today);

  if (!normalized.contains(cursor)) {
    final DateTime yesterday = cursor.subtract(const Duration(days: 1));
    if (!normalized.contains(yesterday)) return 0;
    cursor = yesterday;
  }

  int result = 0;
  while (normalized.contains(cursor)) {
    result++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return result;
}

int bestStreak(Set<DateTime> activeDays) {
  if (activeDays.isEmpty) return 0;

  final List<DateTime> dates =
      activeDays.map<DateTime>(normalizeDate).toSet().toList()..sort();

  int best = 1;
  int running = 1;

  for (int index = 1; index < dates.length; index++) {
    if (dates[index].difference(dates[index - 1]).inDays == 1) {
      running++;
      if (running > best) best = running;
    } else {
      running = 1;
    }
  }
  return best;
}

List<ProgressPoint> impactPointsForPeriod(
  Map<DateTime, DayImpact> impactByDay,
  DateTime end, {
  int dayCount = 30,
}) {
  final List<DateTime> days = daysEndingAt(end, count: dayCount).toList();
  return List<ProgressPoint>.generate(days.length, (int index) {
    final DateTime date = days[index];
    return ProgressPoint(
      index: index,
      date: date,
      value: impactByDay[date]?.score,
    );
  });
}

List<ProgressPoint> scorePointsForPeriod(
  Map<DateTime, double> scoreByDay,
  DateTime end, {
  int dayCount = 30,
}) {
  final List<DateTime> days = daysEndingAt(end, count: dayCount).toList();
  return List<ProgressPoint>.generate(days.length, (int index) {
    final DateTime date = days[index];
    return ProgressPoint(index: index, date: date, value: scoreByDay[date]);
  });
}
