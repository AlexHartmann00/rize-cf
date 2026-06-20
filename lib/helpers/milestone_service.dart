import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:rize/firestore.dart';
import 'package:rize/types/workout.dart';

enum MilestoneCategory { career, weekly, monthly }

enum MilestoneMetric {
  workouts,
  streak,
  repetitions,
  holdSeconds,
  rounds,
  activeDays,
  muscleGroups,
}

class MilestoneDefinition {
  const MilestoneDefinition({
    required this.id,
    required this.category,
    required this.metric,
    required this.target,
    required this.emoji,
    required this.title,
    required this.message,
  });

  final String id;
  final MilestoneCategory category;
  final MilestoneMetric metric;
  final int target;
  final String emoji;
  final String title;
  final String message;
}

class MilestoneState {
  const MilestoneState({
    required this.definition,
    required this.current,
    required this.storageId,
    this.periodLabel,
  });

  final MilestoneDefinition definition;
  final int current;
  final String storageId;
  final String? periodLabel;

  bool get reached => current >= definition.target;
  double get progress =>
      definition.target <= 0 ? 0 : (current / definition.target).clamp(0, 1);

  String get progressLabel {
    switch (definition.metric) {
      case MilestoneMetric.holdSeconds:
        return '${current ~/ 60} / ${definition.target ~/ 60} Min.';
      case MilestoneMetric.repetitions:
        return '$current / ${definition.target} Wdh.';
      case MilestoneMetric.activeDays:
        return '$current / ${definition.target} Tage';
      case MilestoneMetric.muscleGroups:
        return '$current / ${definition.target} Gruppen';
      default:
        return '$current / ${definition.target}';
    }
  }
}

const List<MilestoneDefinition> milestoneDefinitions = <MilestoneDefinition>[
  MilestoneDefinition(
    id: 'first_workout',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.workouts,
    target: 1,
    emoji: '🚀',
    title: 'Der Anfang ist gemacht',
    message: 'Du hast den wichtigsten Schritt genommen: den ersten.',
  ),
  MilestoneDefinition(
    id: 'workouts_5',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.workouts,
    target: 5,
    emoji: '⭐',
    title: 'Du bleibst dran',
    message: 'Fünf Workouts – aus einem Start wird eine Gewohnheit.',
  ),
  MilestoneDefinition(
    id: 'workouts_25',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.workouts,
    target: 25,
    emoji: '🏅',
    title: '25-mal stärker',
    message: 'Du hast Dir bereits 25 starke Momente geschenkt.',
  ),
  MilestoneDefinition(
    id: 'workouts_75',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.workouts,
    target: 75,
    emoji: '🏆',
    title: 'RIZE Veteran',
    message: '75 Workouts. Das ist keine Phase mehr – das bist Du.',
  ),
  MilestoneDefinition(
    id: 'streak_3',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.streak,
    target: 3,
    emoji: '🔥',
    title: 'Funke entfacht',
    message: 'Drei aktive Tage am Stück. Deine Serie lebt.',
  ),
  MilestoneDefinition(
    id: 'streak_7',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.streak,
    target: 7,
    emoji: '🔥',
    title: 'Eine starke Woche',
    message: 'Sieben Tage Serie – Du hältst Dein Versprechen an Dich.',
  ),
  MilestoneDefinition(
    id: 'streak_14',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.streak,
    target: 14,
    emoji: '❤️‍🔥',
    title: 'Unaufhaltsam',
    message: 'Zwei Wochen konsequent. Genau so entsteht Veränderung.',
  ),
  MilestoneDefinition(
    id: 'streak_30',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.streak,
    target: 30,
    emoji: '👑',
    title: '30 Tage RIZE',
    message: 'Einen ganzen Monat lang bist Du für Dich aufgestanden.',
  ),
  MilestoneDefinition(
    id: 'reps_100',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.repetitions,
    target: 100,
    emoji: '🔁',
    title: 'Die ersten Hundert',
    message: '100 Wiederholungen gesammelt – jede einzelne zählt.',
  ),
  MilestoneDefinition(
    id: 'reps_500',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.repetitions,
    target: 500,
    emoji: '💪',
    title: '500 Wiederholungen',
    message: 'Deine Ausdauer wächst mit jeder Wiederholung.',
  ),
  MilestoneDefinition(
    id: 'reps_1000',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.repetitions,
    target: 1000,
    emoji: '⚡',
    title: 'Vierstellig stark',
    message: '1.000 Wiederholungen – eine beeindruckende Leistung.',
  ),
  MilestoneDefinition(
    id: 'reps_5000',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.repetitions,
    target: 5000,
    emoji: '🚀',
    title: 'Bewegungsmaschine',
    message: '5.000 Wiederholungen. Dein Einsatz spricht für sich.',
  ),
  MilestoneDefinition(
    id: 'hold_5',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.holdSeconds,
    target: 300,
    emoji: '⏱️',
    title: 'Fünf Minuten Kontrolle',
    message: 'Insgesamt fünf Minuten gehalten – Ruhe kann stark sein.',
  ),
  MilestoneDefinition(
    id: 'hold_15',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.holdSeconds,
    target: 900,
    emoji: '⏳',
    title: '15 Minuten Fokus',
    message: 'Deine Haltekraft und Dein Fokus wachsen gemeinsam.',
  ),
  MilestoneDefinition(
    id: 'hold_60',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.holdSeconds,
    target: 3600,
    emoji: '🗿',
    title: 'Eine Stunde Stabilität',
    message: '60 Minuten Haltezeit – echte Kontrolle, Stück für Stück.',
  ),
  MilestoneDefinition(
    id: 'rounds_10',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.rounds,
    target: 10,
    emoji: '✅',
    title: '10 Runden geschafft',
    message: 'Zehnmal angefangen und bis zum Ende durchgezogen.',
  ),
  MilestoneDefinition(
    id: 'rounds_25',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.rounds,
    target: 25,
    emoji: '🏁',
    title: '25 starke Runden',
    message: 'Du sammelst keine Ausreden, sondern abgeschlossene Runden.',
  ),
  MilestoneDefinition(
    id: 'rounds_50',
    category: MilestoneCategory.career,
    metric: MilestoneMetric.rounds,
    target: 50,
    emoji: '🎯',
    title: 'Halbes Jahrhundert',
    message: '50 Runden – Deine Konstanz zahlt sich aus.',
  ),
  MilestoneDefinition(
    id: 'week_days_3',
    category: MilestoneCategory.weekly,
    metric: MilestoneMetric.activeDays,
    target: 3,
    emoji: '🌱',
    title: 'Dreifach stark',
    message: 'Drei aktive Tage in dieser Woche. Stark dosiert!',
  ),
  MilestoneDefinition(
    id: 'week_days_5',
    category: MilestoneCategory.weekly,
    metric: MilestoneMetric.activeDays,
    target: 5,
    emoji: '🔥',
    title: 'Wochenheld',
    message: 'Fünf aktive Tage – Du hast diese Woche gerockt.',
  ),
  MilestoneDefinition(
    id: 'week_rounds_10',
    category: MilestoneCategory.weekly,
    metric: MilestoneMetric.rounds,
    target: 10,
    emoji: '🎯',
    title: 'Rundenjäger',
    message: 'Zehn Runden in einer Woche. Saubere Arbeit.',
  ),
  MilestoneDefinition(
    id: 'week_muscles_4',
    category: MilestoneCategory.weekly,
    metric: MilestoneMetric.muscleGroups,
    target: 4,
    emoji: '🧩',
    title: 'Rundum bewegt',
    message: 'Vier Muskelgruppen in einer Woche – schön ausgewogen.',
  ),
  MilestoneDefinition(
    id: 'month_days_12',
    category: MilestoneCategory.monthly,
    metric: MilestoneMetric.activeDays,
    target: 12,
    emoji: '📆',
    title: 'Monat in Bewegung',
    message: 'Zwölf aktive Tage – Bewegung hat einen festen Platz.',
  ),
  MilestoneDefinition(
    id: 'month_workouts_20',
    category: MilestoneCategory.monthly,
    metric: MilestoneMetric.workouts,
    target: 20,
    emoji: '🏆',
    title: '20 Workouts im Monat',
    message: 'Du hast diesen Monat außergewöhnlich konsequent trainiert.',
  ),
  MilestoneDefinition(
    id: 'month_reps_1000',
    category: MilestoneCategory.monthly,
    metric: MilestoneMetric.repetitions,
    target: 1000,
    emoji: '⚡',
    title: 'Monat der Tausend',
    message: '1.000 Wiederholungen in einem Monat – wow.',
  ),
  MilestoneDefinition(
    id: 'month_hold_30',
    category: MilestoneCategory.monthly,
    metric: MilestoneMetric.holdSeconds,
    target: 1800,
    emoji: '⏱️',
    title: '30 Minuten Stabilität',
    message: 'Eine halbe Stunde Haltezeit in diesem Monat gesammelt.',
  ),
  MilestoneDefinition(
    id: 'month_muscles_8',
    category: MilestoneCategory.monthly,
    metric: MilestoneMetric.muscleGroups,
    target: 8,
    emoji: '🌈',
    title: 'Ganzheitlich stark',
    message: 'Acht Muskelgruppen bewegt – Dein Monat war vielseitig.',
  ),
];

Future<List<MilestoneState>> evaluateAndClaimMilestones() async {
  final String userId = authServiceNotifier.value.currentUser?.uid ?? '';
  if (userId.isEmpty) return const <MilestoneState>[];
  final List<ScheduledWorkout> history = await loadWorkoutHistoryFromServer();
  final List<MilestoneState> states = buildMilestoneStates(history);
  final CollectionReference<Map<String, dynamic>> collection = FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('milestones');
  final QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();
  final Set<String> claimed = snapshot.docs.map((doc) => doc.id).toSet();
  final List<MilestoneState> unlocked = states
      .where((state) => state.reached && !claimed.contains(state.storageId))
      .toList(growable: false);
  if (unlocked.isEmpty) return unlocked;

  final WriteBatch batch = FirebaseFirestore.instance.batch();
  for (final MilestoneState state in unlocked) {
    batch.set(collection.doc(state.storageId), <String, dynamic>{
      'milestoneId': state.definition.id,
      'category': state.definition.category.name,
      'title': state.definition.title,
      'current': state.current,
      'target': state.definition.target,
      'periodLabel': state.periodLabel,
      'achievedAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  // Existing users may already satisfy many milestones when this feature is
  // introduced. Claim all of them, but keep the celebration focused.
  return unlocked.length <= 3
      ? unlocked
      : unlocked.sublist(unlocked.length - 3);
}

List<MilestoneState> buildMilestoneStates(List<ScheduledWorkout> history) {
  final DateTime now = DateTime.now();
  final DateTime weekStart = _startOfWeek(now);
  final DateTime monthStart = DateTime(now.year, now.month);
  final _MilestoneSummary career = _summarize(history);
  final _MilestoneSummary week = _summarize(
    history.where((workout) => _isOnOrAfter(workout.scheduledDay, weekStart)),
  );
  final _MilestoneSummary month = _summarize(
    history.where((workout) => _isOnOrAfter(workout.scheduledDay, monthStart)),
  );
  final String weekKey = _dateKey(weekStart);
  final String monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  return milestoneDefinitions
      .map((definition) {
        final _MilestoneSummary summary = switch (definition.category) {
          MilestoneCategory.career => career,
          MilestoneCategory.weekly => week,
          MilestoneCategory.monthly => month,
        };
        final String suffix = switch (definition.category) {
          MilestoneCategory.career => '',
          MilestoneCategory.weekly => '_$weekKey',
          MilestoneCategory.monthly => '_$monthKey',
        };
        final String? periodLabel = switch (definition.category) {
          MilestoneCategory.career => null,
          MilestoneCategory.weekly => 'Diese Woche',
          MilestoneCategory.monthly => 'Dieser Monat',
        };
        return MilestoneState(
          definition: definition,
          current: summary.valueFor(definition.metric),
          storageId: '${definition.id}$suffix',
          periodLabel: periodLabel,
        );
      })
      .toList(growable: false);
}

class _MilestoneSummary {
  const _MilestoneSummary({
    required this.workouts,
    required this.streak,
    required this.repetitions,
    required this.holdSeconds,
    required this.rounds,
    required this.activeDays,
    required this.muscleGroups,
  });

  final int workouts;
  final int streak;
  final int repetitions;
  final int holdSeconds;
  final int rounds;
  final int activeDays;
  final int muscleGroups;

  int valueFor(MilestoneMetric metric) => switch (metric) {
    MilestoneMetric.workouts => workouts,
    MilestoneMetric.streak => streak,
    MilestoneMetric.repetitions => repetitions,
    MilestoneMetric.holdSeconds => holdSeconds,
    MilestoneMetric.rounds => rounds,
    MilestoneMetric.activeDays => activeDays,
    MilestoneMetric.muscleGroups => muscleGroups,
  };
}

_MilestoneSummary _summarize(Iterable<ScheduledWorkout> workouts) {
  int completedWorkouts = 0;
  int repetitions = 0;
  int holdSeconds = 0;
  int rounds = 0;
  final Set<DateTime> activeDays = <DateTime>{};
  final Set<String> muscles = <String>{};

  for (final ScheduledWorkout workout in workouts) {
    final int completedRounds = workout.schedule.fold<int>(
      0,
      (total, step) => total + step.completedUnits,
    );
    if (completedRounds <= 0) continue;
    rounds += completedRounds;
    if (workout.isCompleted) completedWorkouts++;
    if (workout.scheduledDay != null) {
      activeDays.add(_day(workout.scheduledDay!));
    }
    muscles.addAll(workout.usedMuscleGroups);
    for (final WorkoutStep step in workout.schedule) {
      final int fallback = workout.workoutType == WorkoutType.dynamic
          ? (workout.baseReps ?? 0) *
                workout.intensityFactor *
                step.completedUnits
          : (workout.baseSeconds ?? 0) *
                workout.intensityFactor *
                step.completedUnits;
      if (workout.workoutType == WorkoutType.dynamic) {
        repetitions += step.actualValue ?? fallback;
      } else {
        holdSeconds += step.actualValue ?? fallback;
      }
    }
  }

  return _MilestoneSummary(
    workouts: completedWorkouts,
    streak: _bestStreak(activeDays),
    repetitions: repetitions,
    holdSeconds: holdSeconds,
    rounds: rounds,
    activeDays: activeDays.length,
    muscleGroups: muscles.length,
  );
}

int _bestStreak(Set<DateTime> days) {
  if (days.isEmpty) return 0;
  final List<DateTime> sorted = days.toList()..sort();
  int best = 1;
  int current = 1;
  for (int index = 1; index < sorted.length; index++) {
    if (sorted[index].difference(sorted[index - 1]).inDays == 1) {
      current++;
      if (current > best) best = current;
    } else {
      current = 1;
    }
  }
  return best;
}

DateTime _startOfWeek(DateTime date) =>
    _day(date).subtract(Duration(days: date.weekday - DateTime.monday));
DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
bool _isOnOrAfter(DateTime? value, DateTime start) =>
    value != null && !_day(value).isBefore(start);
String _dateKey(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
