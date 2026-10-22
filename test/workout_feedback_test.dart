import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/progress_overview_widgets.dart';
import 'package:rize/widgets/workout_execution_widgets.dart';
import 'package:rize/widgets/milestone_widgets.dart';

Workout exercise(
  String id,
  double impact, {
  List<String> muscles = const ['Chest'],
}) => Workout(
  id: id,
  name: id,
  description: '',
  coachingCues: '',
  usedMuscleGroups: muscles,
  tags: [],
  workoutType: WorkoutType.dynamic,
  impactScore: impact,
  baseReps: 10,
);

ScheduledWorkout finished(Workout base, DateTime day) =>
    ScheduledWorkout.fromBaseWorkout(base, [
      WorkoutStep(timeOfDay: TimeOfDay.any, plannedUnits: 1, completedUnits: 1),
    ], 1)..scheduledDay = day;

void main() {
  test(
    'free selection fills missing slots by proximity before muscle coverage',
    () {
      final near = List.generate(12, (i) => exercise('near-$i', .1 + i * .01));
      final burpee = exercise(
        'Burpee',
        .95,
        muscles: ['Chest', 'Legs', 'Abs', 'Shoulders'],
      );
      final selection = freeWorkoutSelection([...near, burpee], 0);
      expect(selection, hasLength(12));
      expect(selection, isNot(contains(burpee)));
      expect(selection.toSet(), near.toSet());
    },
  );

  test(
    'beginner selection from real catalogue excludes far harder exercises',
    () {
      final data = jsonDecode(
        File('firebase_service/workouts.json').readAsStringSync(),
      );
      final catalogue = (data['exercises'] as List)
          .map((json) => Workout.fromJson(json))
          .toList();
      for (final score in [0.0, .1, .2]) {
        final distances =
            catalogue.map((w) => (w.impactScore - score).abs()).toList()
              ..sort();
        final cutoff = distances[11] > .15 ? distances[11] : .15;
        final selected = freeWorkoutSelection(catalogue, score);
        expect(selected, hasLength(12));
        expect(
          selected.every((w) => (w.impactScore - score).abs() <= cutoff + 1e-9),
          isTrue,
        );
      }
    },
  );

  test('muscle word searches exclude description-only and tag-only hits', () {
    final candidate = exercise('Squat', .3, muscles: ['Quadriceps'])
      ..description = 'Brust und Rücken gerade halten. Langsam absenken.'
      ..tags = ['Chest'];
    expect(workoutMatchesSearch(candidate, 'Brust'), isFalse);
    expect(workoutMatchesSearch(candidate, 'Rücken'), isFalse);
    expect(workoutMatchesSearch(candidate, 'Oberschenkel'), isTrue);
    expect(workoutMatchesSearch(candidate, 'langsam'), isTrue);
    expect(workoutMatchesSearch(candidate, 'Brustkorb'), isFalse);
    candidate.description = 'Brustkorb ruhig halten';
    expect(workoutMatchesSearch(candidate, 'Brustkorb'), isTrue);
    candidate.name = 'Brust Mobilisation';
    expect(workoutMatchesSearch(candidate, 'Brust'), isTrue);
  });

  testWidgets('actual daily impact above one reaches chart without clipping', (
    tester,
  ) async {
    final day = DateTime(2026, 10, 22);
    final entries = List.generate(
      3,
      (i) => WorkoutDayEntry(
        date: day,
        workout: finished(exercise('exercise-$i', .6), day),
      ),
    );
    final stats = ProgressStatistics.fromEntries(entries);
    expect(stats.impactByDay[day]!.score, closeTo(1.8, 1e-9));
    final points = impactPointsForPeriod(stats.impactByDay, day);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressChartCard(
            impactPoints: points,
            scorePoints: const [],
            currentScore: .2,
            lastImpact: stats.lastImpact,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxY, greaterThan(1.8));
    expect(
      chart.data.lineBarsData
          .expand((bar) => bar.spots)
          .any((spot) => (spot.y - 1.8).abs() < 1e-9),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final hint in [
    'Jede Seite zählt als eine Wiederholung',
    'Rechts und links zusammen ergeben eine Wiederholung',
  ]) {
    testWidgets(
      'counting hint with null property type survives and appears before start: $hint',
      (tester) async {
        final base = Workout.fromJson({
          ...exercise('Counting', .2).toJson(),
          'properties': [
            {'propertyType': null, 'helpText': hint},
          ],
        });
        expect(base.isUnilateral, isFalse);
        expect(Workout.fromJson(base.toJson()).countingHints, [hint]);
        final workout = finished(base, DateTime(2026, 10, 22));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutReadyCard(
                  workout: workout,
                  target: 10,
                  onStart: () {},
                ),
              ),
            ),
          ),
        );
        expect(find.text(hint), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(hint)).dy,
          lessThan(tester.getTopLeft(find.text('RUNDE STARTEN')).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('small weekly achievement is offered and acknowledged once', (
    tester,
  ) async {
    final day = DateTime.now();
    final workout = finished(
      exercise(
        'Full body',
        .2,
        muscles: ['Chest', 'Abs', 'Glutes', 'Shoulders'],
      ),
      day,
    );
    workout.historyId = 'current-session';
    final previous = ScheduledWorkout.fromJson(workout.toJson())
      ..scheduledDay = day;
    previous.schedule.single.completedUnits = 0;
    final states = milestonesReachedByCompletion([workout], previous, workout);
    final weekly = states.singleWhere(
      (state) => state.definition.id == 'week_muscles_4',
    );
    expect(weekly.reached, isTrue);
    // Reopening or saving a session that already reached the target adds none.
    expect(milestonesReachedByCompletion([workout], workout, workout), isEmpty);
    final claims = <String, bool>{};
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final coordinator = MilestoneCelebrationCoordinator();
    Future<void> check() => coordinator.celebrate(
      context,
      load: () async => milestonesRequiringCelebration([weekly], claims),
      markShown: (shown) async {
        for (final state in shown) {
          claims[state.storageId] = false;
        }
      },
    );
    final first = check();
    await tester.pumpAndSettle();
    expect(find.text('Rundum bewegt'), findsOneWidget);
    await tester.tap(find.text('STARK – WEITER SO!'));
    await tester.pumpAndSettle();
    await first;
    await check();
    await tester.pumpAndSettle();
    expect(find.text('MEILENSTEIN ERREICHT'), findsNothing);
  });
}
