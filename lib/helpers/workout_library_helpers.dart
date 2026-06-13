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
bool workoutMatchesSearch(
  final Workout workout,
  final String query,
) {
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