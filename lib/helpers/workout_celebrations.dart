import 'dart:math';
import 'package:rize/types/config.dart';
import 'package:rize/types/workout.dart';

const completionMotivations = <String>[
  'Der Rest des Tages gehört dir.',
  'Darauf kannst du stolz sein.',
  'Heute hast du dir selbst Wort gehalten.',
  'Genau so entstehen Gewohnheiten.',
  'Jeder Tag summiert sich.',
  'Dranbleiben schlägt Durchstarten.',
  'Du warst heute da. Das macht den Unterschied.',
  'Abgehakt. Und zwar von dir.',
  'Kleiner Schritt, klare Richtung.',
  'Nicht verhandelt. Einfach gemacht.',
  'Ausreden hatten heute keine Chance.',
  'Konstanz ist dein stärkster Muskel.',
  'Darauf ist Verlass: auf dich.',
  'Wieder ein Baustein auf dem Fundament.',
  'Bewegung, die bleibt. Heute auch.',
  'Ein Tag mehr, der zählt.',
  'Heute hast du dich für dich entschieden.',
  'Jeder Tag wie heute bringt dich weiter.',
  'Regelmäßigkeit ist dein Vorsprung.',
  'Stark. Und morgen wieder.',
  'Sauber durchgezogen.',
  'Wer so dranbleibt, kommt weit.',
  'Mehr braucht es nicht. Nur das, jeden Tag.',
  'Du bist auf dem richtigen Weg.',
  'Wieder einen Tag gewonnen.',
  'Deine Routine wird stärker.',
  'Hier wächst etwas, das hält.',
  'Das kannst du dir anrechnen.',
  'Gut gemacht. Wirklich.',
  'Schon wieder geschafft. Respekt.',
];

String completionMotivation({String? previous, Random? random}) {
  final choices = completionMotivations
      .where((text) => text != previous)
      .toList();
  return choices[(random ?? Random()).nextInt(choices.length)];
}

IntensityLevel intensityLevelForScore(
  List<IntensityLevel> levels,
  double score,
) {
  final eligible = levels.where((level) => score >= level.minScore).toList()
    ..sort((a, b) => b.minScore.compareTo(a.minScore));
  return eligible.isEmpty ? IntensityLevel.unknown() : eligible.first;
}

bool isEarnedLevelUpgrade(
  IntensityLevel? previous,
  IntensityLevel next,
  String? sourceWorkoutId,
) =>
    previous != null &&
    previous.label != 'Unbekannt' &&
    next.level > previous.level &&
    sourceWorkoutId != null &&
    sourceWorkoutId.isNotEmpty;

/// Calendar arithmetic deliberately uses UTC date fields to avoid DST offsets.
/// Three full inactive days require four dates between last activity and today.
int? comebackInactiveDays(
  List<ScheduledWorkout> history,
  ScheduledWorkout previous,
  ScheduledWorkout completed,
) {
  if (!completed.isCompleted || previous.isCompleted || completed.progress <= 0)
    return null;
  final date = completed.scheduledDay;
  if (date == null) return null;
  DateTime day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  final today = day(date);
  final others = history.where(
    (entry) => completed.historyId != null
        ? entry.historyId != completed.historyId
        : !identical(entry, completed),
  );
  final activeDates =
      [...others, previous]
          .where(
            (entry) =>
                entry.scheduledDay != null &&
                entry.schedule.any(
                  (step) => (step.actualValue ?? step.completedUnits) > 0,
                ),
          )
          .map((entry) => day(entry.scheduledDay!))
          .where((date) => !date.isAfter(today))
          .toList()
        ..sort();
  if (activeDates.isEmpty) return null;
  final inactive = today.difference(activeDates.last).inDays - 1;
  return inactive >= 3 ? inactive : null;
}
