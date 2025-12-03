library;

import 'dart:convert';

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

Future<ScheduledWorkout?> loadDailyWorkoutPlan() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('daily_workout_plan');
  if (jsonString == null) {
    return null;
  }
  final Map<String, dynamic> jsonData = jsonDecode(jsonString);

  if((jsonData['day_planned'] as String).length != 10) {
    return null;
  }
  if(DateTime.parse(jsonData['day_planned'] as String).difference(DateTime.now()).inDays != 0) {
    return null;
  }
  try {
    return ScheduledWorkout.fromJson(jsonData);
  } catch (e) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('daily_workout_plan');
    });
    return null;
  }
}