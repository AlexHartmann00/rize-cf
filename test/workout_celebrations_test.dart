import 'dart:math';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/workout_celebrations.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/types/config.dart';
import 'package:rize/widgets/home_page_widgets.dart';

ScheduledWorkout workout(
  DateTime day, {
  String id = 'current',
  int completed = 1,
  int? actual,
}) =>
    ScheduledWorkout(
        id: id,
        name: 'Test',
        description: '',
        coachingCues: '',
        usedMuscleGroups: ['Chest'],
        tags: [],
        workoutType: WorkoutType.dynamic,
        baseReps: 10,
        impactScore: .7,
        intensityFactor: 1,
        schedule: [
          WorkoutStep(
            timeOfDay: TimeOfDay.any,
            plannedUnits: 1,
            completedUnits: completed,
            actualValue: actual,
          ),
        ],
      )
      ..scheduledDay = day
      ..historyId = id;

IntensityLevel level(String label, int rank, double min, double max) =>
    IntensityLevel(
      label: label,
      level: rank,
      minFactor: 1,
      maxFactor: 2,
      minScore: min,
      maxScore: max,
      dynamicPerSetMax: 10,
      setsPerDayMax: 2,
      staticPerSetMax: 30,
    );

void main() {
  test('all 30 supplied motivations rotate without immediate repetition', () {
    expect(completionMotivations.toSet(), hasLength(30));
    final random = Random(42);
    var previous = completionMotivations.first;
    final seen = <String>{};
    for (var i = 0; i < 1000; i++) {
      final next = completionMotivation(previous: previous, random: random);
      expect(next, isNot(previous));
      seen.add(next);
      previous = next;
    }
    expect(seen, completionMotivations.toSet());
  });

  test('level threshold chooses the higher level even when ranges overlap', () {
    final beginner = level('Beginner', 0, 0, .3);
    final athlete = level('Athlet', 1, .3, .6);
    final advanced = level('Fortgeschritten', 2, .6, 1);
    expect(
      intensityLevelForScore([advanced, beginner, athlete], .299),
      beginner,
    );
    expect(intensityLevelForScore([beginner, athlete, advanced], .3), athlete);
    expect(intensityLevelForScore([beginner, athlete, advanced], .8), advanced);
    expect(intensityLevelForScore([], .3).label, 'Unbekannt');
  });

  test('only earned upgrades celebrate, including a level numbered zero', () {
    final beginner = level('Beginner', 0, 0, .3);
    final athlete = level('Athlet', 1, .3, .6);
    expect(isEarnedLevelUpgrade(beginner, athlete, 'workout-1'), isTrue);
    expect(isEarnedLevelUpgrade(beginner, athlete, null), isFalse);
    expect(isEarnedLevelUpgrade(null, athlete, 'workout-1'), isFalse);
    expect(isEarnedLevelUpgrade(athlete, athlete, 'workout-1'), isFalse);
    expect(isEarnedLevelUpgrade(athlete, beginner, 'workout-1'), isFalse);
    expect(
      isEarnedLevelUpgrade(IntensityLevel.unknown(), athlete, 'workout-1'),
      isFalse,
    );
  });

  test(
    'comeback requires three full inactive calendar days, including DST',
    () {
      final today = DateTime(2026, 10, 27, 10);
      final before = workout(today, completed: 0);
      final completed = workout(today);
      expect(comebackInactiveDays([], before, completed), isNull);
      expect(
        comebackInactiveDays(
          [workout(DateTime(2026, 10, 24), id: 'past')],
          before,
          completed,
        ),
        isNull,
      );
      expect(
        comebackInactiveDays(
          [workout(DateTime(2026, 10, 23), id: 'past'), completed],
          before,
          completed,
        ),
        3,
      );
      expect(
        comebackInactiveDays(
          [workout(DateTime(2026, 10, 20), id: 'past')],
          before,
          completed,
        ),
        6,
      );
      expect(
        comebackInactiveDays(
          [workout(today, id: 'earlier')],
          before,
          completed,
        ),
        isNull,
      );
      expect(
        comebackInactiveDays(
          [workout(DateTime(2026, 10, 20), id: 'past')],
          completed,
          completed,
        ),
        isNull,
      );
    },
  );

  test(
    'partial earlier rounds and zero-effort submissions do not trigger comeback',
    () {
      final today = DateTime(2026, 11, 1);
      final before = workout(today, completed: 0);
      final completed = workout(today);
      final past = workout(DateTime(2026, 10, 20), id: 'past');
      final recentPartial = workout(
        today,
        id: 'partial',
        completed: 0,
        actual: 2,
      );
      expect(
        comebackInactiveDays([past, recentPartial], before, completed),
        isNull,
      );
      expect(
        comebackInactiveDays([past], before, workout(today, actual: 0)),
        isNull,
      );
      expect(
        comebackInactiveDays(
          [workout(today, id: 'pending', completed: 0)],
          before,
          completed,
        ),
        isNull,
      );
    },
  );

  test('new monthly milestones have unique ids and reset with the month', () {
    expect(
      milestoneDefinitions.map((m) => m.id).toSet(),
      hasLength(milestoneDefinitions.length),
    );
    final monthly = milestoneDefinitions.where(
      (m) => m.category == MilestoneCategory.monthly,
    );
    expect(monthly.length, greaterThanOrEqualTo(20));
    final now = DateTime(2026, 11, 15);
    final history = [
      for (var day = 1; day <= 3; day++)
        workout(DateTime(now.year, now.month, day), id: 'day-$day'),
      workout(DateTime(now.year, now.month, 0), id: 'old'),
    ];
    final state = buildMilestoneStates(
      history,
    ).singleWhere((m) => m.definition.id == 'month_days_3');
    expect(state.reached, isTrue);
    expect(state.current, 3);
  });

  testWidgets(
    'completed page shows real impact above one and keeps its quote on rebuild',
    (tester) async {
      final workouts = [
        workout(DateTime(2026, 11, 1), id: 'a'),
        workout(DateTime(2026, 11, 1), id: 'b'),
      ];
      Widget view() => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompletedWorkoutHero(
              workouts: workouts,
              streak: 1,
              nextWorkoutIn: '1 Std.',
              progress: 1,
            ),
          ),
        ),
      );
      await tester.pumpWidget(view());
      expect(find.text('1.40'), findsOneWidget);
      final quote = completionMotivations.singleWhere(
        (text) => find.text(text).evaluate().isNotEmpty,
      );
      await tester.pumpWidget(view());
      expect(find.text(quote), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
