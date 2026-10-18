import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/home_page_helpers.dart';
import 'package:rize/helpers/workout_execution_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/types/config.dart';
import 'package:rize/widgets/workout_execution_widgets.dart';
import 'package:rize/widgets/home_page_widgets.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/widgets/progress_overview_widgets.dart';

ScheduledWorkout session({int? actual, int completed = 1, int intensity = 1}) =>
    ScheduledWorkout(
      id: 'reps',
      name: 'Test',
      description: '',
      coachingCues: '',
      usedMuscleGroups: [],
      tags: [],
      workoutType: WorkoutType.dynamic,
      impactScore: 0.5,
      baseReps: 10,
      intensityFactor: intensity,
      schedule: [
        WorkoutStep(
          timeOfDay: TimeOfDay.any,
          plannedUnits: 1,
          completedUnits: completed,
          actualValue: actual,
        ),
      ],
    );

void main() {
  test('submitted repetitions survive storage with proportional progress', () {
    final workout = session(completed: 0);
    workout.schedule[0] = completedWorkoutStep(
      workout.schedule[0],
      actualValue: 1,
    );
    final saved = workout.toJson();
    expect(saved['completionRatio'], 0.1);
    final restored = ScheduledWorkout.fromJson(saved);
    expect(restored.schedule.single.actualValue, 1);
    expect(dailyWorkoutProgress(restored), 0.1);
    expect(DailyWorkoutPlan(id: 'test', workouts: [restored]).progress, 0.1);
  });

  test(
    'zero, partial, full and excess repetitions use the intensity target',
    () {
      for (final entry in <int, double>{
        0: 0,
        1: 0.05,
        10: 0.5,
        20: 1,
        25: 1,
      }.entries) {
        expect(session(actual: entry.key, intensity: 2).progress, entry.value);
      }
      expect(session().progress, 1); // Legacy completed round.
      expect(session(completed: 0).progress, 0);
    },
  );

  test('extra repetitions cannot compensate for an unstarted round', () {
    final workout = session(actual: 25);
    workout.schedule = [
      ...workout.schedule,
      WorkoutStep(timeOfDay: TimeOfDay.any, plannedUnits: 1, completedUnits: 0),
    ];
    expect(workout.progress, 0.5);
  });

  for (final size in [
    const Size(320, 480),
    const Size(390, 780),
    const Size(700, 400),
  ]) {
    testWidgets('repetition indicator stays circular at $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicRepControl(
              current: 1,
              target: 10,
              onChanged: (_) {},
              onComplete: () {},
            ),
          ),
        ),
      );
      final ring = tester.getSize(
        find.byKey(const ValueKey<String>('repetition-progress-ring')),
      );
      expect(ring.width, closeTo(ring.height, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('partial completion shows the real percentage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutCompletionView(
            workout: session(),
            actualValue: 1,
            saving: false,
            onConfirm: () {},
          ),
        ),
      ),
    );
    expect(
      find.text('1 von 10 Wiederholungen · 10 % geschafft'),
      findsOneWidget,
    );
    expect(find.text('Alle Wiederholungen geschafft!'), findsNothing);
  });
  testWidgets('finished daily plan keeps partial goal attainment visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletedWorkoutHero(
            workouts: [session(actual: 1)],
            progress: 0.1,
            streak: 1,
            nextWorkoutIn: '1 Std.',
          ),
        ),
      ),
    );
    expect(find.text('10 % des Tagesziels geschafft'), findsOneWidget);
    expect(find.text('Training beendet!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('completed plan shows every exercise and combined impact', (
    tester,
  ) async {
    final workouts = List.generate(
      5,
      (index) => session(actual: 2)..name = 'Übung ${index + 1}',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompletedWorkoutHero(
              workouts: workouts,
              progress: .2,
              streak: 1,
              nextWorkoutIn: '1 Std.',
            ),
          ),
        ),
      ),
    );
    for (var index = 1; index <= 5; index++) {
      expect(find.textContaining('Übung $index'), findsOneWidget);
    }
    expect(find.text('5 Übungen abgeschlossen'), findsOneWidget);
    expect(find.text('0.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('plan size survives storage for score normalization', () {
    final workout = session()..planExerciseCount = 5;
    final adjusted = IntensityLevel.unknown().applyToWorkout(workout);
    expect(ScheduledWorkout.fromJson(adjusted.toJson()).planExerciseCount, 5);
  });

  test('partial impact persists and feeds statistics for reps and seconds', () {
    for (final type in WorkoutType.values) {
      final workout = session(actual: 5)
        ..workoutType = type
        ..baseSeconds = 10;
      expect(workout.effectiveImpactScore, .25);
      final restored = ScheduledWorkout.fromJson(workout.toJson());
      expect(restored.effectiveImpactScore, .25);
      final stats = ProgressStatistics.fromEntries([
        WorkoutDayEntry(date: DateTime(2026, 9, 22), workout: restored),
      ]);
      expect(stats.lastImpact!.score, .25);
    }
  });

  test(
    'unilateral target survives storage without doubling partial impact',
    () {
      final workout = session(actual: 5);
      workout.schedule[0].targetValue = 20;
      final restored = ScheduledWorkout.fromJson(workout.toJson());
      expect(restored.progress, .25);
      expect(restored.effectiveImpactScore, .125);
    },
  );

  testWidgets('partial seconds show scaled completion impact', (tester) async {
    final workout = session()
      ..workoutType = WorkoutType.static
      ..baseSeconds = 10;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutCompletionView(
            workout: workout,
            actualValue: 5,
            saving: false,
            onConfirm: () {},
          ),
        ),
      ),
    );
    expect(find.text('5 von 10 Sekunden · 50 % geschafft'), findsOneWidget);
    expect(find.text('Impact 0.25'), findsOneWidget);
  });

  testWidgets('calendar day shows partial values impact and earned score', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityCalendarCard(
            month: DateTime(2026, 9),
            daySummaries: {
              22: CalendarDaySummary(
                completion: .5,
                impactScore: .25,
                impactLevel: ImpactLevel.low,
                workoutCount: 1,
                workouts: [
                  CalendarWorkoutSummary(
                    name: 'Testübung',
                    completedRounds: 1,
                    plannedRounds: 1,
                    completion: .5,
                    impactScore: .25,
                    actualValue: 5,
                    targetValue: 10,
                    unit: 'Sekunden',
                    scoreDelta: .002,
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('22'));
    await tester.pumpAndSettle();
    expect(find.text('5 / 10 Sekunden · 50 % geschafft'), findsOneWidget);
    expect(find.text('Impact 0.25 · Fitnessscore +0.20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
