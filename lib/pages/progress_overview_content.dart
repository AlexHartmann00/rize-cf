import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/date_helpers.dart';
import 'package:rize/helpers/progress_firestore_parser.dart';
import 'package:rize/helpers/progress_formatters.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/widgets/progress_overview_widgets.dart';
import 'package:rize/widgets/milestone_widgets.dart';
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
                    label: 'Spins',
                    value: '${statistics.completedUnits}',
                    icon: Icons.cyclone_rounded,
                  ),
                  MetricItem(
                    label: 'Wiederholungen',
                    value: '${statistics.dynamicRepetitions}',
                    icon: Icons.repeat_rounded,
                  ),
                  MetricItem(
                    label: 'Haltezeit',
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
              ProgressChartCard(
                impactPoints: impactPoints,
                scorePoints: scorePoints,
                currentScore: currentScore,
                lastImpact: statistics.lastImpact,
              ),
              const SizedBox(height: 16),
              ActivityCalendarCard(
                month: today,
                activeDays: activeDayNumbersForMonth(
                  statistics.activeDays,
                  today,
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
