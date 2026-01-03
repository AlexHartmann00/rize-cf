import 'package:rize/types/workout.dart';

class WorkoutExtentRestriction {
  String levelId;
  int dynamicPerSetMax;
  int setsPerDayMax;
  int staticPerSetMax;

  WorkoutExtentRestriction({
    required this.levelId,
    required this.dynamicPerSetMax,
    required this.setsPerDayMax,
    required this.staticPerSetMax,
  });

  factory WorkoutExtentRestriction.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return WorkoutExtentRestriction(
      levelId: id,
      dynamicPerSetMax: json['dynamicPerSet'] as int,
      setsPerDayMax: json['setsPerDay'] as int,
      staticPerSetMax: json['staticPerSetSeconds'] as int,
    );
  }
}

class IntensityLevel {
  String label;
  int level;
  int minFactor;
  int maxFactor;
  double minScore;
  double maxScore;
  int dynamicPerSetMax;
  int setsPerDayMax;
  int staticPerSetMax;

  double progressToNextLevel(double currentScore) {
    if (currentScore >= maxScore) {
      return 1.0;
    }
    if (currentScore <= minScore) {
      return 0.0;
    }
    return (currentScore - minScore) / (maxScore - minScore);
  }

  IntensityLevel({
    required this.label,
    required this.level,
    required this.minFactor,
    required this.maxFactor,
    required this.minScore,
    required this.maxScore,
    required this.dynamicPerSetMax,
    required this.setsPerDayMax,
    required this.staticPerSetMax,
  });

  factory IntensityLevel.fromJson(Map<String, dynamic> json) {
    return IntensityLevel(
      label: json['label'] as String,
      level: json['level'] as int,
      minFactor: json['factorMin'] as int,
      maxFactor: json['factorMax'] as int,
      minScore: (json['intensityMin'] as num).toDouble(),
      maxScore: (json['intensityMax'] as num).toDouble(),
      dynamicPerSetMax: json['dynamicPerSet'] as int,
      setsPerDayMax: json['setsPerDay'] as int,
      staticPerSetMax: json['staticPerSetSeconds'] as int,
    );
  }

  factory IntensityLevel.unknown() {
    return IntensityLevel(
      label: 'Unbekannt',
      level: 0,
      minFactor: 1,
      maxFactor: 7,
      minScore: 0.0,
      maxScore: 1.0,
      dynamicPerSetMax: 100,
      setsPerDayMax: 3,
      staticPerSetMax: 600,
    );
  }

  ScheduledWorkout applyToWorkout(ScheduledWorkout workout) {
    int newFactor = _clampFactor(workout.intensityFactor);
    return ScheduledWorkout(
      id: workout.id,
      name: workout.name,
      description: workout.description,
      coachingCues: workout.coachingCues,
      usedMuscleGroups: workout.usedMuscleGroups,
      baseReps: (workout.baseReps != null)
          ? (workout.baseReps! * newFactor > dynamicPerSetMax
                    ? dynamicPerSetMax / newFactor
                    : workout.baseReps!)
                .round()
          : null,
      baseSeconds: (workout.baseSeconds != null)
          ? (workout.baseSeconds! * newFactor > staticPerSetMax
                    ? staticPerSetMax / newFactor
                    : workout.baseSeconds!)
                .round()
          : null,
      workoutType: workout.workoutType,
      impactScore: workout.impactScore,
      videoExplanationUrl: workout.videoExplanationUrl,
      schedule: workout.schedule,
      intensityFactor: newFactor,
    );
  }

  int _clampFactor(int factor) {
    if (factor < minFactor) {
      return minFactor;
    }
    if (factor > maxFactor) {
      return maxFactor;
    }
    return factor;
  }
}

class Config {
  List<IntensityLevel> intensityLevels;

  Config({required this.intensityLevels});

  factory Config.fromJson(Map<String, dynamic> json) {
    List<IntensityLevel> intensityLevelsList = [];
    for (MapEntry entry in json.entries) {
      intensityLevelsList.add(IntensityLevel.fromJson(entry.value));
    }

    return Config(intensityLevels: intensityLevelsList);
  }
}
