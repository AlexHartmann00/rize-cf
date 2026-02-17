import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/auth_service.dart';
import 'package:rize/firestore.dart';
import 'package:rize/utils.dart' as utils;
import 'package:rize/types/muscle_group.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WorkoutType { static, dynamic }

enum ImpactLevel { low, medium, high }

class Workout {
  String id;
  String name;
  String description;
  String coachingCues;
  List<String> usedMuscleGroups;
  List<String> tags;
  int? baseReps;
  int? baseSeconds;
  WorkoutType workoutType;
  double impactScore;
  String? videoExplanationUrl;

  String get filterString {
    String tagString = tags.join(' ');
    String muscleGroupString = usedMuscleGroups.join(' ');
    return '$name $description $tagString $muscleGroupString'.toLowerCase();
  }

  String get youtubeVideoId{
    if(videoExplanationUrl == null){
      return '';
    }

    if(!videoExplanationUrl!.contains('youtu')){
      return '';
    }

    return videoExplanationUrl!.split('/').last;
  }

  String get durationString => baseSeconds != null
      ? '${(baseSeconds ?? 0)} Sekunden'
      : '${(baseReps ?? 0)} Wiederholungen';

  String get durationStringShort => baseSeconds != null
      ? '${(baseSeconds ?? 0)} Sek.'
      : '${(baseReps ?? 0)} Wdh.';

  ImpactLevel get impactLevel {
    if (impactScore < 0.33) {
      return ImpactLevel.low;
    }
    if (impactScore < 0.67) {
      return ImpactLevel.medium;
    }
    return ImpactLevel.high;
  }

  Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.coachingCues,
    required this.usedMuscleGroups,
    required this.tags,
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
      usedMuscleGroups: (json['muscleGroups'] ?? [])
          .map<String>((e) => e as String)
          .toList(),
      tags: (json['tags'] ?? []).map<String>((e) => e as String).toList(),
      baseReps: json['baseReps'] as int?,
      baseSeconds: json['baseSeconds'] as int?,
      workoutType: WorkoutType.values.firstWhere(
        (e) => e.name.contains(json['type'] as String? ?? 'static'),
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
    'muscleGroups': usedMuscleGroups,
    'tags': tags,
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
  List<WorkoutStep> schedule;
  int intensityFactor;
  DateTime? scheduledDay;

  ScheduledWorkout({
    // super fields
    required super.id,
    required super.name,
    required super.description,
    required super.coachingCues,
    required super.usedMuscleGroups,
    required super.tags,
    required super.workoutType,
    required super.impactScore,
    super.baseReps,
    super.baseSeconds,
    super.videoExplanationUrl,
    // own field
    required this.schedule,
    required this.intensityFactor,
  });

  String get durationString => baseSeconds != null
      ? '${(baseSeconds ?? 0) * intensityFactor} Sekunden'
      : '${(baseReps ?? 0) * intensityFactor} Wiederholungen';

  String get durationStringShort => baseSeconds != null
      ? '${(baseSeconds ?? 0) * intensityFactor} Sek.'
      : '${(baseReps ?? 0) * intensityFactor} Wdh.';

  bool get isCompleted {
    for (var entry in schedule) {
      if (entry.completedUnits < entry.plannedUnits) {
        return false;
      }
    }
    return true;
  }

  factory ScheduledWorkout.fromBaseWorkout(
    Workout base,
    List<WorkoutStep> schedule,
    int intensityFactor,
  ) {
    return ScheduledWorkout(
      id: base.id,
      name: base.name,
      description: base.description,
      coachingCues: base.coachingCues,
      usedMuscleGroups: base.usedMuscleGroups,
      tags: base.tags,
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
    List<WorkoutStep> schedule = [];
    if (json['schedule'] != null) {
      for (var entry in json['schedule']) {
        TimeOfDay timeOfDay = TimeOfDay.values.firstWhere(
          (e) => e.name == (entry['timeOfDay'] as String? ?? 'any'),
          orElse: () => TimeOfDay.any,
        );
        int plannedUnits = entry['plannedUnits'] as int;
        int completed = entry['completedUnits'] as int;
        schedule.add(
          WorkoutStep(
            timeOfDay: timeOfDay,
            plannedUnits: plannedUnits,
            completedUnits: completed,
          ),
        );
      }
    }
    int intensityFactor = json['intensityFactor'] as int? ?? 1;

    return ScheduledWorkout.fromBaseWorkout(
      baseWorkout,
      schedule,
      intensityFactor
    );
  }

  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'schedule': schedule
          .map(
            (entry) => {
              'timeOfDay': entry.timeOfDay.name,
              'plannedUnits': entry.plannedUnits,
              'completedUnits': entry.completedUnits,
            },
          )
          .toList(),
      'intensityFactor': intensityFactor,
    });
    return baseJson;
  }

  Future<void> saveAsDailyWorkoutPlan() async {
    print('FB usage indirect: Saving daily workout plan');
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // Map<String, dynamic> jsonData = toJson();
    // DateTime now = DateTime.now();
    // DateFormat df = DateFormat('yyyy-MM-dd');
    uploadWorkoutToServer(this);
    // jsonData['day_planned'] = df.format(now);
    // String jsonString = jsonEncode(jsonData);
    // await prefs.setString('daily_workout_plan', jsonString);
  }
}

class WorkoutScheduleEntry {
  TimeOfDay timeOfDay;
  int plannedUnits;
  int completedUnits;

  WorkoutScheduleEntry({
    required this.timeOfDay,
    required this.plannedUnits,
    required this.completedUnits,
  });
}

class WorkoutStep {
  TimeOfDay timeOfDay;
  int plannedUnits;
  int completedUnits;

  WorkoutStep({
    required this.timeOfDay,
    required this.plannedUnits,
    required this.completedUnits,
  });

  factory WorkoutStep.fromTuple((TimeOfDay, int, int) input) {
    return WorkoutStep(
      timeOfDay: input.$1,
      plannedUnits: input.$2,
      completedUnits: input.$3,
    );
  }
}
