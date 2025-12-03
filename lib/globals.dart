library;

import 'package:rize/types/user.dart';
import 'package:rize/types/workout.dart';

late List<Workout> workoutLibrary;
ScheduledWorkout? dailyWorkoutPlan;
int navBarIndex = 0;

double intensityScoreTolerance = 0.15;

UserData? userData;

String? authenticatedUserId;
