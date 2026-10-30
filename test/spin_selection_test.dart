import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/types/workout.dart';

Workout exercise(String id, List<String> muscles, {List<String>? tags}) =>
    Workout(
      id: id,
      name: id,
      description: '',
      coachingCues: '',
      usedMuscleGroups: muscles,
      tags: tags ?? <String>[],
      workoutType: WorkoutType.dynamic,
      impactScore: 0.5,
      baseReps: 10,
    );

Map<String, int> muscleCounts(List<Workout> selection) {
  final Map<String, int> counts = <String, int>{};
  for (final Workout workout in selection) {
    for (final String group in workout.usedMuscleGroups.toSet()) {
      counts.update(group, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return counts;
}

void main() {
  test('five exercise spins spread a chest and thigh heavy catalogue', () {
    final List<Workout> catalogue = <Workout>[
      for (int i = 0; i < 20; i++)
        exercise('chest-$i', <String>['chest', 'triceps', 'front shoulders']),
      for (int i = 0; i < 20; i++)
        exercise('thigh-$i', <String>['quadriceps', 'glutes', 'hamstrings']),
      exercise('back', <String>['upper back', 'rear shoulders']),
      exercise('calves', <String>['calves']),
      exercise('core', <String>['abs', 'obliques']),
    ];

    for (int seed = 0; seed < 100; seed++) {
      final List<Workout> selection = selectWorkoutsForSpin(
        workouts: catalogue,
        count: 5,
        random: Random(seed),
      );

      expect(selection, hasLength(5), reason: 'seed $seed');
      expect(selection.map((workout) => workout.id).toSet(), hasLength(5));
      expect(muscleCounts(selection).values, everyElement(1));
    }
    expect(catalogue, hasLength(43));
  });

  test('spins keep balancing after all muscle groups have been covered', () {
    final List<Workout> catalogue = <Workout>[
      for (final String group in <String>['chest', 'quadriceps', 'upper back'])
        for (int i = 0; i < 8; i++) exercise('$group-$i', <String>[group]),
    ];

    for (int seed = 0; seed < 100; seed++) {
      final List<Workout> selection = selectWorkoutsForSpin(
        workouts: catalogue,
        count: 5,
        random: Random(seed),
      );
      expect(selection, hasLength(5));
      expect(
        muscleCounts(selection).values,
        everyElement(lessThanOrEqualTo(2)),
      );
    }
  });

  test('secondary muscles contribute to overlap', () {
    for (int seed = 0; seed < 100; seed++) {
      final List<Workout> selection = selectWorkoutsForSpin(
        workouts: <Workout>[
          exercise('chest', <String>['chest', 'triceps']),
          exercise('arms', <String>['biceps', 'triceps']),
          exercise('legs', <String>['quadriceps']),
        ],
        count: 2,
        random: Random(seed),
      );
      expect(selection.any((workout) => workout.id == 'legs'), isTrue);
    }
  });

  test(
    'spin respects focus and exclusions while covering selected muscles',
    () {
      for (int seed = 0; seed < 100; seed++) {
        final List<Workout> selection = selectWorkoutsForSpin(
          workouts: <Workout>[
            exercise('chest', <String>['chest', 'triceps']),
            exercise('chest-again', <String>['chest', 'front shoulders']),
            exercise('legs', <String>['quadriceps']),
            exercise('calves', <String>['calves']),
            exercise(
              'excluded',
              <String>['quadriceps'],
              tags: <String>['Knee'],
            ),
          ],
          count: 2,
          random: Random(seed),
          muscleFilter: <String>{'chest', 'quadriceps'},
          excludedTags: <String>{' knee '},
        );
        expect(selection, hasLength(2));
        expect(selection.any((workout) => workout.id == 'legs'), isTrue);
        expect(selection.any((workout) => workout.id == 'excluded'), isFalse);
        expect(selection.any((workout) => workout.id == 'calves'), isFalse);
      }
    },
  );

  test('narrow focus fills the plan even when overlap is unavoidable', () {
    final List<Workout> selection = selectWorkoutsForSpin(
      workouts: <Workout>[
        for (int i = 0; i < 6; i++) exercise('chest-$i', <String>['chest']),
        exercise('legs', <String>['quadriceps']),
      ],
      count: 5,
      random: Random(0),
      muscleFilter: <String>{'chest'},
    );
    expect(selection, hasLength(5));
    expect(selection.map((workout) => workout.id).toSet(), hasLength(5));
    expect(muscleCounts(selection), <String, int>{'chest': 5});
  });

  test('spin handles empty, insufficient and non-positive requests', () {
    final List<Workout> catalogue = <Workout>[
      exercise('chest', <String>['chest']),
      exercise('legs', <String>['quadriceps']),
    ];
    for (final int count in <int>[-1, 0, 5]) {
      final List<Workout> selection = selectWorkoutsForSpin(
        workouts: catalogue,
        count: count,
        random: Random(0),
      );
      expect(selection, hasLength(count <= 0 ? 0 : 2));
    }
    expect(
      selectWorkoutsForSpin(workouts: <Workout>[], count: 5, random: Random(0)),
      isEmpty,
    );
  });

  test('equally balanced plans retain random tie-breaking', () {
    final Set<String> plans = <String>{
      for (int seed = 0; seed < 30; seed++)
        selectWorkoutsForSpin(
          workouts: <Workout>[
            exercise('chest', <String>['chest']),
            exercise('legs', <String>['quadriceps']),
            exercise('back', <String>['upper back']),
          ],
          count: 2,
          random: Random(seed),
        ).map((workout) => workout.id).join(','),
    };
    expect(plans.length, greaterThan(1));
  });
}
