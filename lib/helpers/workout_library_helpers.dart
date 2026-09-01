import 'dart:math';

import 'package:rize/types/workout.dart';

/// Converts text into a normalized search representation.
///
/// This makes searches:
/// - case-insensitive
/// - insensitive to repeated whitespace
/// - insensitive to common German diacritics
/// - more tolerant of punctuation
String normalizeWorkoutSearchText(final String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Returns whether a workout matches every word in the search query.
///
/// Splitting the query into tokens means a search such as:
///
/// `brust dynamisch`
///
/// matches a workout whose filter string contains both words, even when they
/// are not directly next to each other.
bool workoutMatchesSearch(final Workout workout, final String query) {
  final String normalizedQuery = normalizeWorkoutSearchText(query);

  if (normalizedQuery.isEmpty) {
    return true;
  }

  final String searchableText = normalizeWorkoutSearchText(
    workout.filterString,
  );

  final List<String> queryTokens = normalizedQuery
      .split(' ')
      .where((final String token) => token.isNotEmpty)
      .toList(growable: false);

  return queryTokens.every(searchableText.contains);
}

/// Filters workouts without modifying the original list.
List<Workout> filterWorkoutLibrary(
  final Iterable<Workout> workouts,
  final String query,
) {
  if (query.trim().isEmpty) {
    return List<Workout>.unmodifiable(workouts);
  }

  return List<Workout>.unmodifiable(
    workouts.where(
      (final Workout workout) => workoutMatchesSearch(workout, query),
    ),
  );
}

/// Smallest practical free catalogue: greedily covers every muscle group with
/// workouts close to the questionnaire result.
List<Workout> freeWorkoutSelection(
  Iterable<Workout> workouts,
  double intensityScore, {
  int minimumWorkoutCount = 6,
}) {
  final List<Workout> all = workouts.toList(growable: false);
  if (all.isEmpty) return const <Workout>[];

  final double score = intensityScore.clamp(0, 1);
  final Set<String> uncoveredMuscles = all
      .expand((Workout workout) => workout.usedMuscleGroups)
      .toSet();
  final Set<WorkoutType> uncoveredTypes = all
      .map((Workout workout) => workout.workoutType)
      .toSet();
  final List<Workout> remaining = List<Workout>.of(all);
  final List<Workout> selected = <Workout>[];

  while ((uncoveredMuscles.isNotEmpty || uncoveredTypes.isNotEmpty) &&
      remaining.isNotEmpty) {
    remaining.sort((Workout a, Workout b) {
      double value(Workout workout) {
        final int muscleCoverage = workout.usedMuscleGroups
            .where(uncoveredMuscles.contains)
            .length;
        final int typeCoverage = uncoveredTypes.contains(workout.workoutType)
            ? 1
            : 0;
        final double scoreDistance = (workout.impactScore - score).abs();
        return muscleCoverage * 100 + typeCoverage * 24 - scoreDistance * 35;
      }

      final int comparison = value(b).compareTo(value(a));
      return comparison != 0 ? comparison : a.id.compareTo(b.id);
    });
    final Workout best = remaining.removeAt(0);
    selected.add(best);
    uncoveredMuscles.removeAll(best.usedMuscleGroups);
    uncoveredTypes.remove(best.workoutType);
  }

  remaining.sort((Workout a, Workout b) {
    final int comparison = (a.impactScore - score).abs().compareTo(
      (b.impactScore - score).abs(),
    );
    return comparison != 0 ? comparison : a.id.compareTo(b.id);
  });
  final int desiredCount = minimumWorkoutCount.clamp(1, all.length);
  for (final Workout workout in remaining) {
    if (selected.length >= desiredCount) break;
    selected.add(workout);
  }

  return List<Workout>.unmodifiable(selected);
}

List<Workout> availableWorkoutsForUser({
  required Iterable<Workout> workouts,
  required double intensityScore,
  required bool isPro,
}) {
  return isPro
      ? List<Workout>.unmodifiable(workouts)
      : freeWorkoutSelection(workouts, intensityScore);
}

/// Applies the inclusive muscle-group filter and tag-based exclusions.
bool workoutMatchesMuscleFilters(
  Workout workout, {
  Set<String> includedMuscleGroups = const <String>{},
  Set<String> excludedTags = const <String>{},
}) {
  final Set<String> normalizedExcludedTags = excludedTags
      .map((String tag) => tag.trim().toLowerCase())
      .where((String tag) => tag.isNotEmpty)
      .toSet();
  final bool matchesMuscleFocus =
      includedMuscleGroups.isEmpty ||
      workout.usedMuscleGroups.any(includedMuscleGroups.contains);
  final bool hasExcludedTag = workout.tags.any(
    (String tag) => normalizedExcludedTags.contains(tag.trim().toLowerCase()),
  );
  return matchesMuscleFocus && !hasExcludedTag;
}

/// Picks unique exercises while maximizing newly covered muscle groups.
/// Pass a shuffled input list when randomized tie-breaking is desired.
List<Workout> selectDiverseWorkouts({
  required Iterable<Workout> workouts,
  required int count,
  Set<String> muscleFilter = const <String>{},
  Set<String> excludedTags = const <String>{},
}) {
  final List<Workout> remaining = workouts
      .where(
        (Workout workout) => workoutMatchesMuscleFilters(
          workout,
          includedMuscleGroups: muscleFilter,
          excludedTags: excludedTags,
        ),
      )
      .toList();
  final List<Workout> result = <Workout>[];
  final Set<String> coveredMuscles = <String>{};
  final Set<String> coveredFilterMuscles = <String>{};

  while (result.length < count && remaining.isNotEmpty) {
    Workout best = remaining.first;
    int bestNewFilterCoverage = -1;
    int bestNewCoverage = -1;
    for (final Workout candidate in remaining) {
      final int newFilterCoverage = candidate.usedMuscleGroups
          .where(
            (String group) =>
                muscleFilter.contains(group) &&
                !coveredFilterMuscles.contains(group),
          )
          .length;
      final int newCoverage = candidate.usedMuscleGroups
          .where((String group) => !coveredMuscles.contains(group))
          .length;
      if (newFilterCoverage > bestNewFilterCoverage ||
          (newFilterCoverage == bestNewFilterCoverage &&
              newCoverage > bestNewCoverage)) {
        best = candidate;
        bestNewFilterCoverage = newFilterCoverage;
        bestNewCoverage = newCoverage;
      }
    }
    result.add(best);
    coveredMuscles.addAll(best.usedMuscleGroups);
    coveredFilterMuscles.addAll(
      best.usedMuscleGroups.where(muscleFilter.contains),
    );
    remaining.remove(best);
  }
  return List<Workout>.unmodifiable(result);
}

/// Draws workouts randomly and without replacement from the eligible pool.
List<Workout> selectWorkoutsForSpin({
  required Iterable<Workout> workouts,
  required int count,
  required Random random,
  Set<String> muscleFilter = const <String>{},
  Set<String> excludedTags = const <String>{},
}) {
  if (count <= 0) return const <Workout>[];

  final List<Workout> candidates = workouts
      .where(
        (Workout workout) => workoutMatchesMuscleFilters(
          workout,
          includedMuscleGroups: muscleFilter,
          excludedTags: excludedTags,
        ),
      )
      .toList();
  if (candidates.isEmpty) return const <Workout>[];

  final List<Workout> selected = <Workout>[];
  final int selectionCount = count.clamp(0, candidates.length);
  while (selected.length < selectionCount) {
    final int randomIndex = random.nextInt(candidates.length);
    selected.add(candidates.removeAt(randomIndex));
  }
  return List<Workout>.unmodifiable(selected);
}

/// Keeps random tie-breaking from the input order, but moves exercises and
/// muscle groups trained during the previous days towards the end.
List<Workout> prioritizeWorkoutsForRecentVariety({
  required Iterable<Workout> workouts,
  required Iterable<ScheduledWorkout> history,
  DateTime? now,
  int lookbackDays = 2,
}) {
  final List<Workout> result = workouts.toList();
  if (result.length < 2 || lookbackDays <= 0) {
    return List<Workout>.unmodifiable(result);
  }

  final DateTime reference = now ?? DateTime.now();
  final DateTime today = DateTime(
    reference.year,
    reference.month,
    reference.day,
  );
  final List<ScheduledWorkout> recent = history
      .where((workout) {
        final DateTime? scheduledDay = workout.scheduledDay;
        if (scheduledDay == null) return false;
        final DateTime day = DateTime(
          scheduledDay.year,
          scheduledDay.month,
          scheduledDay.day,
        );
        final int age = today.difference(day).inDays;
        return age >= 1 && age <= lookbackDays;
      })
      .toList(growable: false);

  int penalty(Workout candidate) {
    int value = 0;
    for (final ScheduledWorkout previous in recent) {
      final DateTime day = DateTime(
        previous.scheduledDay!.year,
        previous.scheduledDay!.month,
        previous.scheduledDay!.day,
      );
      final int age = today.difference(day).inDays;
      final int weight = lookbackDays - age + 1;
      if (candidate.id == previous.id) value += 1000 * weight;
      value +=
          candidate.usedMuscleGroups
              .where(previous.usedMuscleGroups.contains)
              .length *
          100 *
          weight;
    }
    return value;
  }

  result.sort((Workout first, Workout second) {
    return penalty(first).compareTo(penalty(second));
  });
  return List<Workout>.unmodifiable(result);
}
