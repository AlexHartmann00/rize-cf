import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/workout_execution_helpers.dart';
import 'package:rize/pages/workout_details_page.dart';
import 'package:rize/pages/workout_execution_page.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/workout_details_widgets.dart';

void main() {
  testWidgets('technique route returns completion for the same stored session', (
    tester,
  ) async {
    final workout =
        ScheduledWorkout(
            id: 'test',
            name: 'Testübung',
            description: '',
            coachingCues: '',
            usedMuscleGroups: [],
            tags: [],
            workoutType: WorkoutType.dynamic,
            baseReps: 10,
            impactScore: .5,
            intensityFactor: 1,
            schedule: [
              WorkoutStep(
                timeOfDay: TimeOfDay.any,
                plannedUnits: 1,
                completedUnits: 1,
              ),
              WorkoutStep(
                timeOfDay: TimeOfDay.any,
                plannedUnits: 1,
                completedUnits: 0,
              ),
            ],
          )
          ..historyId = 'existing-session'
          ..scheduledDay = DateTime(2026, 11, 20)
          ..planId = 'daily-plan';
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailsPage(workout: workout),
                ),
              );
            },
            child: const Text('Technik ansehen'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Technik ansehen'));
    await tester.pumpAndSettle();
    tester
        .widget<WorkoutDetailsBottomAction>(
          find.byType(WorkoutDetailsBottomAction),
        )
        .onStart();
    await tester.pumpAndSettle();
    final execution = tester.widget<WorkoutExecutionPage>(
      find.byType(WorkoutExecutionPage),
    );
    expect(identical(execution.workout, workout), isTrue);
    expect(execution.scheduleEntryIndex, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Complete the execution route as the successful persistence callback does.
    execution.workout.schedule[1] = completedWorkoutStep(
      execution.workout.schedule[1],
      actualValue: 10,
      targetValue: 10,
    );
    Navigator.of(tester.element(find.byType(WorkoutExecutionPage))).pop(true);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Technik ansehen'), findsOneWidget);
    final stored = ScheduledWorkout.fromJson(workout.toJson());
    expect(stored.isCompleted, isTrue);
    expect(workout.historyId, 'existing-session');
    expect(stored.planId, 'daily-plan');
    expect(stored.schedule[1].actualValue, 10);
    expect(tester.takeException(), isNull);
  });
}
