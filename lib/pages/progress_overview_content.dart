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
        stream: _workoutHistory.limit(500).snapshots(),
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
                stream: _scoreHistory.limit(500).snapshots(),
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
                        today: today,
                        statistics: statistics,
                        impactPoints: impactPointsForPeriod(
                          statistics.impactByDay,
                          today,
                        ),
                        scorePoints: scorePointsForPeriod(scores, today),
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
    required this.history,
  });

  final DateTime today;
  final ProgressStatistics statistics;
  final List<ProgressPoint> impactPoints;
  final List<ProgressPoint> scorePoints;
  final List<ScheduledWorkout> history;

  @override
  Widget build(BuildContext context) {
    final int current = currentStreak(statistics.activeDays, today);
    final int best = bestStreak(statistics.activeDays);
    final dynamic userData = globals.userData;
    final bool isPro = userData?.isPro == true;
    final String level = userData?.intensityLevel.label ?? 'Start';
    final double levelProgress = userData == null
        ? 0
        : (userData.intensityLevel.progressToNextLevel(userData.intensityScore)
                  as num)
              .toDouble();

    final double? currentScore = scorePoints
        .where((ProgressPoint point) => point.value != null)
        .map((ProgressPoint point) => point.value)
        .lastOrNull;

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
              const SizedBox(height: 16),
              MilestoneOverviewCard(history: history),
              const SizedBox(height: 16),
              if (isPro) ...<Widget>[
                ProgressChartCard(
                  impactPoints: impactPoints,
                  scorePoints: scorePoints,
                  currentScore: currentScore,
                  lastImpact: statistics.lastImpact,
                ),
                const SizedBox(height: 16),
                ActivityCalendarCard(
                  month: today,
                  daySummaries: _calendarSummaries(history, today),
                ),
              ] else
                ProFeatureLock(
                  title: 'Mehr Fortschritt mit RIZE Pro',
                  description:
                      'Entdecke Deine Verlaufskurven und alle Details im Aktivitätskalender.',
                  onTap: () => showProUpgradeSheet(
                    context,
                    source: 'progress_after_milestones',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

Map<int, CalendarDaySummary> _calendarSummaries(
  List<ScheduledWorkout> history,
  DateTime month,
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
    int completed = 0;
    double impactScore = 0;
    ImpactLevel level = ImpactLevel.low;
    for (final ScheduledWorkout workout in workouts) {
      impactScore = (impactScore + workout.impactScore).clamp(0, 1);
      level = workout.impactLevel.index > level.index
          ? workout.impactLevel
          : level;
      for (final WorkoutStep step in workout.schedule) {
        planned += step.plannedUnits;
        completed += step.completedUnits.clamp(0, step.plannedUnits);
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
                completedRounds: workoutCompleted,
                plannedRounds: workoutPlanned,
              );
            })
            .toList(growable: false),
      ),
    );
  });
}
