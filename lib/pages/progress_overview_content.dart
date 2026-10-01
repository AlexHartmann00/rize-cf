import 'package:rize/helpers/workout_execution_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/date_helpers.dart';
import 'package:rize/helpers/progress_firestore_parser.dart';
import 'package:rize/helpers/progress_formatters.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/widgets/progress_overview_widgets.dart';
import 'package:rize/widgets/milestone_widgets.dart';
import 'package:rize/widgets/pro_upgrade_cta.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/types/config.dart';

class ProgressOverviewContent extends StatelessWidget {
  const ProgressOverviewContent({super.key, required this.userId});

  final String userId;

  CollectionReference<Map<String, Object?>> get _workoutHistory =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workoutHistory');

  CollectionReference<Map<String, Object?>> get _scoreHistory =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('scoreHistory');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot<Map<String, Object?>>>(
        stream: _workoutHistory.snapshots(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, Object?>>>
              workoutSnapshot,
            ) {
              if (workoutSnapshot.hasError) {
                return ProgressErrorState(
                  message: workoutSnapshot.error.toString(),
                );
              }
              if (!workoutSnapshot.hasData) {
                return const ProgressLoadingState();
              }

              final List<WorkoutDayEntry> entries = parseWorkoutHistory(
                workoutSnapshot.data!.docs,
              );
              final ProgressStatistics statistics =
                  ProgressStatistics.fromEntries(entries);

              return StreamBuilder<QuerySnapshot<Map<String, Object?>>>(
                stream: _scoreHistory.snapshots(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<QuerySnapshot<Map<String, Object?>>>
                      scoreSnapshot,
                    ) {
                      if (scoreSnapshot.hasError) {
                        return ProgressErrorState(
                          message: scoreSnapshot.error.toString(),
                        );
                      }
                      if (!scoreSnapshot.hasData) {
                        return const ProgressLoadingState();
                      }

                      final DateTime today = normalizeDate(DateTime.now());
                      final Map<DateTime, double> scores = parseScoreHistory(
                        scoreSnapshot.data!.docs,
                      );

                      return _ProgressDashboard(
                        scoreDeltas: <String, double>{
                          for (final doc in scoreSnapshot.data!.docs)
                            if (doc.data()['type'] == 'workout_completed' &&
                                doc.data()['workoutId'] is String &&
                                doc.data()['delta'] is num)
                              doc.data()['workoutId']! as String:
                                  (doc.data()['delta']! as num).toDouble(),
                        },
                        today: today,
                        statistics: statistics,
                        impactPoints: impactPointsForPeriod(
                          statistics.impactByDay,
                          today,
                        ),
                        scorePoints: scorePointsForPeriod(scores, today),
                        currentScore: latestScoreFromHistory(scores),
                        history: entries
                            .map((WorkoutDayEntry entry) => entry.workout)
                            .toList(growable: false),
                      );
                    },
              );
            },
      ),
    );
  }
}

class _ProgressDashboard extends StatelessWidget {
  const _ProgressDashboard({
    required this.today,
    required this.statistics,
    required this.impactPoints,
    required this.scorePoints,
    required this.currentScore,
    required this.history,
    required this.scoreDeltas,
  });

  final DateTime today;
  final ProgressStatistics statistics;
  final List<ProgressPoint> impactPoints;
  final List<ProgressPoint> scorePoints;
  final double? currentScore;
  final List<ScheduledWorkout> history;
  final Map<String, double> scoreDeltas;

  @override
  Widget build(BuildContext context) {
    final int current = currentStreak(statistics.activeDays, today);
    final int best = bestStreak(statistics.activeDays);
    final dynamic userData = globals.userData;
    final bool isPro = userData?.isPro == true;
    final double effectiveScore = currentScore ?? userData?.intensityScore ?? 0;
    final IntensityLevel intensityLevel = globals.intensityLevels.firstWhere(
      (IntensityLevel candidate) =>
          effectiveScore >= candidate.minScore &&
          effectiveScore <= candidate.maxScore,
      orElse: () => userData?.intensityLevel ?? IntensityLevel.unknown(),
    );
    final String level = intensityLevel.label;
    final double levelProgress = intensityLevel.progressToNextLevel(
      effectiveScore,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Dein Fortschritt',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Deine Entwicklung, Aktivität und Trainingsleistung.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.64),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              ProgressHero(
                currentStreak: current,
                bestStreak: best,
                level: level,
                levelProgress: levelProgress,
                activeDaysThisMonth: activeDayNumbersForMonth(
                  statistics.activeDays,
                  today,
                ).length,
              ),
              const SizedBox(height: 16),
              MetricGrid(
                items: <MetricItem>[
                  MetricItem(
                    label: 'Einheiten',
                    value: '${statistics.completedUnits}',
                    icon: Icons.cyclone_rounded,
                  ),
                  MetricItem(
                    label: 'Wiederholungen',
                    value: '${statistics.dynamicRepetitions}',
                    icon: Icons.repeat_rounded,
                  ),
                  MetricItem(
                    label: 'Zeitbasierte Übungen',
                    value: formatDuration(statistics.staticSeconds),
                    icon: Icons.timer_outlined,
                  ),
                  MetricItem(
                    label: 'Aktive Tage',
                    value: '${statistics.activeDays.length}',
                    icon: Icons.calendar_month_rounded,
                  ),
                ],
              ),
              if (isPro) ...<Widget>[
                const SizedBox(height: 16),
                MilestoneOverviewCard(history: history),
                const SizedBox(height: 16),
                ProgressChartCard(
                  impactPoints: impactPoints,
                  scorePoints: scorePoints,
                  currentScore: currentScore,
                  lastImpact: statistics.lastImpact,
                ),
                const SizedBox(height: 16),
                WorkoutHistoryCalendar(
                  today: today,
                  history: history,
                  scoreDeltas: scoreDeltas,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ProFeatureLock(
                    title: 'Mehr Fortschritt mit RIZE Pro',
                    description:
                        'Entdecke Meilensteine, Deine Verlaufskurven und alle Details im Aktivitätskalender.',
                    onTap: () => showProUpgradeSheet(
                      context,
                      source: 'progress_free_lock',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<int, CalendarDaySummary> _calendarSummaries(
  List<ScheduledWorkout> history,
  DateTime month,
  Map<String, double> scoreDeltas,
) {
  final Map<int, List<ScheduledWorkout>> byDay =
      <int, List<ScheduledWorkout>>{};
  for (final ScheduledWorkout workout in history) {
    final DateTime? date = workout.scheduledDay;
    if (date == null || date.year != month.year || date.month != month.month) {
      continue;
    }
    byDay.putIfAbsent(date.day, () => <ScheduledWorkout>[]).add(workout);
  }

  return byDay.map((int day, List<ScheduledWorkout> workouts) {
    int planned = 0;
    double completed = 0;
    double impactScore = 0;
    ImpactLevel level = ImpactLevel.low;
    for (final ScheduledWorkout workout in workouts) {
      impactScore = (impactScore + workout.effectiveImpactScore).clamp(0, 1);
      level = workout.effectiveImpactLevel.index > level.index
          ? workout.effectiveImpactLevel
          : level;
      for (final WorkoutStep step in workout.schedule) {
        planned += step.plannedUnits;
        completed += workout.achievedUnits(step);
      }
    }
    return MapEntry<int, CalendarDaySummary>(
      day,
      CalendarDaySummary(
        completion: planned <= 0 ? 0 : (completed / planned).clamp(0.0, 1.0),
        impactScore: impactScore,
        impactLevel: level,
        workoutCount: workouts.length,
        workouts: workouts
            .map((ScheduledWorkout workout) {
              final int workoutPlanned = workout.schedule.fold<int>(
                0,
                (int total, WorkoutStep step) => total + step.plannedUnits,
              );
              final int workoutCompleted = workout.schedule.fold<int>(
                0,
                (int total, WorkoutStep step) =>
                    total + step.completedUnits.clamp(0, step.plannedUnits),
              );
              return CalendarWorkoutSummary(
                name: workout.name,
                scoreDelta: scoreDeltas[workout.historyId],
                completedRounds: workoutCompleted,
                plannedRounds: workoutPlanned,
                completion: workout.progress,
                impactScore: workout.effectiveImpactScore,
                actualValue: workout.schedule.fold<int>(
                  0,
                  (sum, step) =>
                      sum +
                      (step.actualValue ??
                          (workoutTargetValue(workout) * step.completedUnits)),
                ),
                targetValue: workout.schedule.fold<int>(
                  0,
                  (sum, step) =>
                      sum +
                      (step.targetValue ?? workoutTargetValue(workout)) *
                          step.plannedUnits,
                ),
                unit: workout.workoutType == WorkoutType.dynamic
                    ? 'Wiederholungen'
                    : 'Sekunden',
              );
            })
            .toList(growable: false),
      ),
    );
  });
}

class WorkoutHistoryCalendar extends StatefulWidget {
  const WorkoutHistoryCalendar({
    super.key,
    required this.today,
    required this.history,
    required this.scoreDeltas,
  });

  final DateTime today;
  final List<ScheduledWorkout> history;
  final Map<String, double> scoreDeltas;

  @override
  State<WorkoutHistoryCalendar> createState() => _WorkoutHistoryCalendarState();
}

class _WorkoutHistoryCalendarState extends State<WorkoutHistoryCalendar> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  void _changeMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
  }

  @override
  Widget build(BuildContext context) {
    final DateTime currentMonth = DateTime(widget.today.year, widget.today.month);
    return ActivityCalendarCard(
      month: _month,
      daySummaries: _calendarSummaries(widget.history, _month, widget.scoreDeltas),
      onPreviousMonth: () => _changeMonth(-1),
      onNextMonth: _month.isBefore(currentMonth) ? () => _changeMonth(1) : null,
    );
  }
}
