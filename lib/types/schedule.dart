import 'package:flutter/material.dart';

class WorkoutStep {
  TimeOfDay timeOfDay;
  int plannedUnits;
  int completedUnits;

  WorkoutStep({
    required this.timeOfDay,
    required this.plannedUnits,
    required this.completedUnits,
  });
}
