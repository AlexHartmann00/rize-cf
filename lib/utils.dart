library;

import 'dart:convert';

import 'package:rize/firestore.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/types/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

Duration parseDuration(String input) {
  input = input.trim().toLowerCase();

  if (input.endsWith('ms')) {
    final value = int.parse(input.substring(0, input.length - 2));
    return Duration(milliseconds: value);
  } else if (input.endsWith('s')) {
    final value = int.parse(input.substring(0, input.length - 1));
    return Duration(seconds: value);
  } else if (input.endsWith('m')) {
    final value = int.parse(input.substring(0, input.length - 1));
    return Duration(minutes: value);
  } else if (input.endsWith('h')) {
    final value = int.parse(input.substring(0, input.length - 1));
    return Duration(hours: value);
  } else {
    // fallback: treat as seconds if no unit
    final value = int.parse(input);
    return Duration(seconds: value);
  }
}


bool timeOfDayIsCurrent(TimeOfDay timeOfDay) {
  DateTime now = DateTime.now();
  bool inCorrectTime =
      (timeOfDay == TimeOfDay.any) ||
      ((timeOfDay == TimeOfDay.morning && (now.hour <= 12)) ||
          (timeOfDay == TimeOfDay.afternoon &&
              (now.hour >= 12 && now.hour <= 17)) ||
          (timeOfDay == TimeOfDay.evening && (now.hour >= 17)));
  return inCorrectTime;
}

bool timeOfDayIsPast(TimeOfDay timeOfDay) {
  DateTime now = DateTime.now();
  if ((timeOfDay == TimeOfDay.any) || (timeOfDay == TimeOfDay.evening)) {
    return false;
  }
  bool isPast =
      ((timeOfDay == TimeOfDay.morning && (now.hour >= 12)) ||
      (timeOfDay == TimeOfDay.afternoon && (now.hour >= 17)));
  return isPast;
}

String workoutScheduleToString(List<WorkoutStep> schedule) {
  int anyUnits = 0;
  String timeOfDayNames = '';
  for (WorkoutStep element in schedule) {
    if (element.timeOfDay == TimeOfDay.any) {
      anyUnits += element.plannedUnits;
    } else {
      if (timeOfDayNames.isEmpty) {
        timeOfDayNames = element.timeOfDay.name;
      } else {
        timeOfDayNames += ' / ' + element.timeOfDay.name;
      }
    }
  }

  if (anyUnits == 0) {
    return timeOfDayNames;
  }
  if (timeOfDayNames.isEmpty) {
    return '$anyUnits x';
  } else {
    return '$timeOfDayNames + $anyUnits x';
  }
}

int computeCurrentStreakFromHistory(List<ScheduledWorkout> history) {
  int streak = 0;
  DateTime today = DateTime.now();
  history.sort((a, b) => b.scheduledDay!.compareTo(a.scheduledDay!));

  for (ScheduledWorkout workout in history) {
    DateTime workoutDate = workout.scheduledDay!;
    Duration difference = today.difference(workoutDate);
    if (difference.inDays == streak) {
      if (workout.isCompleted) {
        streak += 1;
      } else {
        break;
      }
    } else if (difference.inDays > streak) {
      break;
    }
  }

  return streak;
}