library;

import 'package:fitness_app/types/user.dart';
import 'package:fitness_app/types/workout.dart';

late List<Workout> workoutLibrary;
ScheduledWorkout? dailyWorkoutPlan;
int navBarIndex = 0;

double intensityScoreTolerance = 0.15;

UserData? userData;

String? authenticatedUserId;
