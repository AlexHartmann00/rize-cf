import 'dart:convert';

import 'package:fitness_app/utils.dart' as utils;
import 'package:fitness_app/types/muscle_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WorkoutType { static, dynamic }

enum ImpactLevel { low, medium, high }

class Workout {
  String id;
  String name;
  String description;
  String coachingCues;
  List<String> usedMuscleGroups;
  int? baseReps;
  int? baseSeconds;
  ImpactLevel impactLevel;
  WorkoutType workoutType;
  double impactScore;
  String? videoExplanationUrl;

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.coachingCues,
    required this.usedMuscleGroups,
    required this.impactLevel,
    required this.workoutType,
    required this.impactScore,
    this.baseReps,
    this.baseSeconds,
    this.videoExplanationUrl,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coachingCues: json['coachingCues'] as String? ?? '',
      usedMuscleGroups: (json['usedMuscleGroups'] ?? [])
          .map<String>((e) => e as String)
          .toList(),
      baseReps: json['baseReps'] as int?,
      baseSeconds: json['baseSeconds'] as int?,
      impactLevel: ImpactLevel.values.firstWhere(
        (e) => e.name == (json['impactLevel'] as String? ?? 'low'),
        orElse: () => ImpactLevel.low,
      ),
      workoutType: WorkoutType.values.firstWhere(
        (e) => e.name == (json['workoutType'] as String? ?? 'static'),
        orElse: () => WorkoutType.static,
      ),
      impactScore: (json['impactScore'] as num?)?.toDouble() ?? 0.0,
      videoExplanationUrl: json['videoExplanationUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'coachingCues': coachingCues,
    'usedMuscleGroups': usedMuscleGroups,
    'baseReps': baseReps,
    'baseSeconds': baseSeconds,
    'impactLevel': impactLevel.name,
    'workoutType': workoutType.name,
    'impactScore': impactScore,
    'videoExplanationUrl': videoExplanationUrl,
  };
}

enum TimeOfDay { any, morning, afternoon, evening }

class ScheduledWorkout extends Workout {
  /// (TimeOfDay, int, bool) = (time, planned reps/seconds/units, completed)
  List<(TimeOfDay, int, int)> schedule;
  int intensityFactor;

  ScheduledWorkout({
    // super fields
    required super.id,
    required super.name,
    required super.description,
    required super.coachingCues,
    required super.usedMuscleGroups,
    required super.impactLevel,
    required super.workoutType,
    required super.impactScore,
    super.baseReps,
    super.baseSeconds,
    super.videoExplanationUrl,
    // own field
    required this.schedule,
    required this.intensityFactor,
  });

  String get durationString => workoutType == WorkoutType.static
      ? '${(baseSeconds ?? 0) * intensityFactor} Sekunden'
      : '${(baseReps ?? 0) * intensityFactor} Wiederholungen';

  factory ScheduledWorkout.fromBaseWorkout(
    Workout base,
    List<(TimeOfDay, int, int)> schedule,
    int intensityFactor,
  ) {
    return ScheduledWorkout(
      id: base.id,
      name: base.name,
      description: base.description,
      coachingCues: base.coachingCues,
      usedMuscleGroups: base.usedMuscleGroups,
      impactLevel: base.impactLevel,
      workoutType: base.workoutType,
      impactScore: base.impactScore,
      baseReps: base.baseReps,
      baseSeconds: base.baseSeconds,
      videoExplanationUrl: base.videoExplanationUrl,
      schedule: schedule,
      intensityFactor:
          intensityFactor, // Default intensity factor, can be adjusted as needed
    );
  }

  factory ScheduledWorkout.fromJson(Map<String, dynamic> json) {
    Workout baseWorkout = Workout.fromJson(json);
    List<(TimeOfDay, int, int)> schedule = [];
    if (json['schedule'] != null) {
      for (var entry in json['schedule']) {
        TimeOfDay timeOfDay = TimeOfDay.values.firstWhere(
          (e) => e.name == (entry['timeOfDay'] as String? ?? 'any'),
          orElse: () => TimeOfDay.any,
        );
        int plannedUnits = entry['plannedUnits'] as int;
        int completed = entry['completedUnits'] as int;
        schedule.add((timeOfDay, plannedUnits, completed));
      }
    }
    int intensityFactor = json['intensityFactor'] as int? ?? 1;

    return ScheduledWorkout(
      id: baseWorkout.id,
      name: baseWorkout.name,
      description: baseWorkout.description,
      coachingCues: baseWorkout.coachingCues,
      usedMuscleGroups: baseWorkout.usedMuscleGroups,
      impactLevel: baseWorkout.impactLevel,
      workoutType: baseWorkout.workoutType,
      impactScore: baseWorkout.impactScore,
      baseReps: baseWorkout.baseReps,
      baseSeconds: baseWorkout.baseSeconds,
      videoExplanationUrl: baseWorkout.videoExplanationUrl,
      schedule: schedule,
      intensityFactor: intensityFactor,
    );
  }

  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'schedule': schedule
          .map(
            (entry) => {
              'timeOfDay': entry.$1.name,
              'plannedUnits': entry.$2,
              'completedUnits': entry.$3,
            },
          )
          .toList(),
      'intensityFactor': intensityFactor,
    });
    return baseJson;
  }

  Future<void> saveAsDailyWorkoutPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> jsonData = toJson();
    DateTime now = DateTime.now();
    jsonData['day_planned'] = '${now.year}-${now.month}-${now.day}';
    String jsonString = jsonEncode(jsonData);
    await prefs.setString('daily_workout_plan', jsonString);
  }
}
