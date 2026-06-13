
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:rize/types/config.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/utils.dart';

List<Workout> workoutsForUserIntensity({
  required Iterable<Workout> workouts,
  required double? intensityScore,
  required double tolerance,
}) {
  if (intensityScore == null) {
    return List<Workout>.unmodifiable(workouts);
  }

  final List<Workout> matches = workouts.where((Workout workout) {
    return workout.impactScore >= intensityScore - tolerance &&
        workout.impactScore <= intensityScore + tolerance;
  }).toList(growable: false);

  // Never leave the spin without options because the configured tolerance is
  // temporarily too narrow.
  return matches.isEmpty
      ? List<Workout>.unmodifiable(workouts)
      : List<Workout>.unmodifiable(matches);
}

List<int> buildIntensityFactors(IntensityLevel level) {
  final int min = level.minFactor;
  final int max = level.maxFactor < min ? min : level.maxFactor;

  return List<int>.generate(
    max - min + 1,
    (int index) => min + index,
    growable: false,
  );
}

List<List<WorkoutStep>> buildScheduleOptions(IntensityLevel level) {
  final int maximumSets = level.setsPerDayMax < 1 ? 1 : level.setsPerDayMax;

  return List<List<WorkoutStep>>.generate(
    maximumSets,
    (int index) => List<WorkoutStep>.generate(
      index + 1,
      (_) => WorkoutStep.fromTuple((TimeOfDay.any, 1, 0)),
      growable: false,
    ),
    growable: false,
  );
}

bool isDailyPlanActionable(ScheduledWorkout workout) {
  return workout.schedule.any((WorkoutStep step) {
    if (step.completedUnits >= step.plannedUnits) {
      return false;
    }

    return !timeOfDayIsPast(step.timeOfDay);
  });
}

bool canResetDailyPlan(ScheduledWorkout workout) {
  return workout.schedule.every(
    (WorkoutStep step) => step.completedUnits == 0,
  );
}

int completedScheduleUnits(ScheduledWorkout workout) {
  return workout.schedule.fold<int>(
    0,
    (int total, WorkoutStep step) => total + step.completedUnits,
  );
}

int scheduledScheduleUnits(ScheduledWorkout workout) {
  return workout.schedule.fold<int>(
    0,
    (int total, WorkoutStep step) => total + step.plannedUnits,
  );
}

double dailyWorkoutProgress(ScheduledWorkout workout) {
  final int scheduled = scheduledScheduleUnits(workout);
  if (scheduled <= 0) return 0;

  return (completedScheduleUnits(workout) / scheduled).clamp(0.0, 1.0);
}

String homeGreeting(String? displayName, DateTime now) {
  final String name = _firstName(displayName) ?? 'Sportler';

  if (now.hour < 11) return 'Guten Morgen, $name';
  if (now.hour < 17) return 'Hallo, $name';
  return 'Guten Abend, $name';
}

String dailyMotivation(DateTime now) {
  if (now.hour < 11) {
    return 'Starte bewegt in den Tag – Dein Körper wird es Dir danken.';
  }
  if (now.hour < 17) {
    return 'Ein kurzer Impuls reicht, um heute etwas für Dich zu tun.';
  }
  return 'Der Tag ist noch nicht vorbei. Zeit für Deinen starken Abschluss.';
}

String completedMessage(int streak) {
  if (streak <= 1) {
    return 'Starker Anfang. Morgen machen wir daraus eine Serie.';
  }
  if (streak < 7) {
    return '$streak Tage am Stück – Du baust gerade echte Routine auf.';
  }
  return '$streak Tage Serie. Konsequenz schlägt Motivation.';
}

Duration timeUntilTomorrow(DateTime now) {
  final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
  return tomorrow.difference(now);
}

String compactDuration(Duration duration) {
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);

  if (hours <= 0) return '${minutes} Min.';
  if (minutes == 0) return '$hours Std.';
  return '$hours Std. $minutes Min.';
}

String? _firstName(String? displayName) {
  final String value = displayName?.trim() ?? '';
  if (value.isEmpty) return null;
  return value.split(RegExp(r'\s+')).first;
}
