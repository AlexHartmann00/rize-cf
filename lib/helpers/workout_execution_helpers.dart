import 'package:flutter/material.dart';
import 'package:rize/types/workout.dart';

enum WorkoutExecutionPhase {
  ready,
  countdown,
  active,
  paused,
  sideTransition,
  completed,
  saving,
  error,
}

enum WorkoutExecutionSide { left, right }

int workoutTargetValue(ScheduledWorkout workout) {
  if (workout.workoutType == WorkoutType.dynamic) {
    return (workout.baseReps ?? 0) * workout.intensityFactor;
  }

  return (workout.baseSeconds ?? 0) * workout.intensityFactor;
}

String workoutTargetLabel(ScheduledWorkout workout) {
  return workout.workoutType == WorkoutType.dynamic
      ? 'Wiederholungen'
      : 'Sekunden halten';
}

String workoutTypeLabel(WorkoutType type) {
  return type == WorkoutType.dynamic ? 'Dynamisch' : 'Statisch';
}

IconData workoutTypeIcon(WorkoutType type) {
  return type == WorkoutType.dynamic
      ? Icons.repeat_rounded
      : Icons.timer_outlined;
}

String workoutSideLabel(WorkoutExecutionSide side) {
  return side == WorkoutExecutionSide.left
      ? 'Linke Seite'
      : 'Rechte Seite';
}

String workoutSideShortLabel(WorkoutExecutionSide side) {
  return side == WorkoutExecutionSide.left ? 'Links' : 'Rechts';
}

double workoutExecutionProgress({
  required int current,
  required int target,
}) {
  if (target <= 0) return 0;
  return (current / target).clamp(0.0, 1.0);
}

String formatExecutionTime(int totalSeconds) {
  final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final int minutes = safeSeconds ~/ 60;
  final int seconds = safeSeconds % 60;

  if (minutes <= 0) return '$seconds';
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String completionHeadline(ScheduledWorkout workout) {
  if (workout.isUnilateral) return 'Beide Seiten geschafft!';

  return workout.workoutType == WorkoutType.dynamic
      ? 'Alle Wiederholungen geschafft!'
      : 'Stark gehalten!';
}

String completionMessage(ScheduledWorkout workout) {
  if (workout.isUnilateral) {
    return 'Links und rechts vollständig absolviert – sauber ausgeglichen.';
  }

  return workout.workoutType == WorkoutType.dynamic
      ? 'Du hast die Runde vollständig abgeschlossen.'
      : 'Du bist bis zum Ende drangeblieben.';
}

WorkoutStep completedWorkoutStep(WorkoutStep currentStep) {
  return WorkoutStep(
    timeOfDay: currentStep.timeOfDay,
    plannedUnits: currentStep.plannedUnits,
    completedUnits: currentStep.plannedUnits,
  );
}
