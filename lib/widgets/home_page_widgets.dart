import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/rize_card.dart';
import 'package:rize/helpers/workout_celebrations.dart';

class CoachFloHomeHeader extends StatelessWidget {
  const CoachFloHomeHeader({
    super.key,
    required this.greeting,
    required this.message,
    this.streak,
  });

  final String greeting;
  final String message;
  final int? streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.64),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (streak != null) ...<Widget>[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9857).withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFFF9857).withOpacity(0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF9857),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class CoachFloManifestoCard extends StatelessWidget {
  const CoachFloManifestoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      accentColor: rizeCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: rizeCyan.withOpacity(0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'COACH FLO × RIZE',
              style: TextStyle(
                color: rizeCyan,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Das Geheimnis des Erfolgs ist anzufangen.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dein Training passt sich Deinem Niveau und Deinem Alltag an. '
            'Heute zählt nicht perfekt – heute zählt gemacht.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.68),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DailySpinHero extends StatelessWidget {
  const DailySpinHero({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF67C9F4),
            Color(0xFF176BC7),
            Color(0xFF0A4395),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1670D2).withOpacity(0.38),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -38,
            bottom: -55,
            child: Icon(
              Icons.cyclone_rounded,
              size: 190,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Deine Tagesaufgabe',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Eine passende Aufgabe, Deine Intensität und ein klarer Impuls für heute.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A4C9E),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'TAGESAUFGABE ZIEHEN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomePrinciplesRow extends StatelessWidget {
  const HomePrinciplesRow({super.key});

  @override
  Widget build(BuildContext context) {
    const List<_Principle> principles = <_Principle>[
      _Principle(
        icon: Icons.tune_rounded,
        title: 'Für Dich',
        subtitle: 'Individuell dosiert',
      ),
      _Principle(
        icon: Icons.schedule_rounded,
        title: 'Alltagstauglich',
        subtitle: 'Kurz und wirksam',
      ),
      _Principle(
        icon: Icons.health_and_safety_rounded,
        title: 'Präventiv',
        subtitle: 'Stark für morgen',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = 10;
        final double width = (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: principles
              .map((_Principle principle) {
                return SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: <Widget>[
                        Icon(principle.icon, color: rizeCyan, size: 21),
                        const SizedBox(height: 8),
                        Text(
                          principle.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          principle.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.50),
                            fontSize: 10,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class DailyWorkoutCard extends StatelessWidget {
  const DailyWorkoutCard({
    super.key,
    required this.workout,
    required this.progress,
    required this.onOpenTechnique,
    required this.schedule,
    required this.muscleVisualization,
    this.eyebrow = 'DEIN WORKOUT HEUTE',
    this.onReset,
  });

  final ScheduledWorkout workout;
  final double progress;
  final VoidCallback onOpenTechnique;
  final Widget schedule;
  final Widget muscleVisualization;
  final String eyebrow;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      accentColor: rizeCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[rizeCyan, rizeBlue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.48),
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.09),
              valueColor: const AlwaysStoppedAnimation<Color>(rizeCyan),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress <= 0
                ? 'Bereit, wenn Du es bist.'
                : '${(progress * 100).round()} % für heute geschafft',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          schedule,
          const SizedBox(height: 12),
          muscleVisualization,
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenTechnique,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Technik ansehen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: rizeBlue,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              if (onReset != null) ...<Widget>[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Workout neu wählen',
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String? _lastCompletionMotivation;

class CompletedWorkoutHero extends StatefulWidget {
  const CompletedWorkoutHero({
    super.key,
    required this.workouts,
    required this.streak,
    required this.nextWorkoutIn,
    required this.progress,
  });

  final List<ScheduledWorkout> workouts;
  final int streak;
  final double progress;
  final String nextWorkoutIn;

  @override
  State<CompletedWorkoutHero> createState() => _CompletedWorkoutHeroState();
}

class _CompletedWorkoutHeroState extends State<CompletedWorkoutHero> {
  late String _motivation;

  void _chooseMotivation() {
    _motivation = completionMotivation(previous: _lastCompletionMotivation);
    _lastCompletionMotivation = _motivation;
  }

  String _sessionKey(CompletedWorkoutHero value) => value.workouts
      .map(
        (workout) =>
            '${workout.historyId ?? workout.id}:${workout.scheduledDay}',
      )
      .join('|');

  @override
  void initState() {
    super.initState();
    _chooseMotivation();
  }

  @override
  void didUpdateWidget(covariant CompletedWorkoutHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sessionKey(oldWidget) != _sessionKey(widget)) _chooseMotivation();
  }

  @override
  Widget build(BuildContext context) {
    final complete = widget.progress >= 1;
    final impact = widget.workouts.fold<double>(
      0,
      (sum, workout) => sum + workout.effectiveImpactScore,
    );
    final progress = widget.progress.clamp(0.0, 1.0);
    return Container(
      key: const ValueKey('completed-workout-card'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163E62), Color(0xFF0C2847)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rizeGreen.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: rizeGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TAGESAUFGABE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete ? 'Abgeschlossen' : 'Training beendet',
                      style: const TextStyle(
                        color: rizeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            complete ? 'Für heute geschafft!' : 'Training beendet!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.12,
              letterSpacing: -.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _motivation,
            style: const TextStyle(
              color: Color(0xFFBCD0E0),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white54,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.workouts.length} ${widget.workouts.length == 1 ? 'Übung' : 'Übungen'} abgeschlossen',
                      style: const TextStyle(
                        color: Color(0xFFDFEAF2),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.workouts
                          .map((workout) => workout.name)
                          .join(' · '),
                      style: const TextStyle(
                        color: Color(0xFF94AEC5),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CompletedMetric(
                  icon: Icons.local_fire_department_rounded,
                  value:
                      '${widget.streak} ${widget.streak == 1 ? 'Tag' : 'Tage'}',
                  label: 'Aktuelle Serie',
                  color: const Color(0xFFFFAD77),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompletedMetric(
                  icon: Icons.bolt_rounded,
                  value: impact.toStringAsFixed(2),
                  label: 'Impact',
                  color: rizeCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: rizeGreen,
              backgroundColor: Colors.white.withValues(alpha: .08),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${(widget.progress * 100).round()} % des Tagesziels geschafft',
            style: const TextStyle(
              color: Color(0xFF94AEC5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFF294761)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF94AEC5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nächste Tagesaufgabe',
                      style: TextStyle(color: Color(0xFF94AEC5), fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'In ${widget.nextWorkoutIn} bereit.',
                      style: const TextStyle(
                        color: Color(0xFFDFEAF2),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedMetric extends StatelessWidget {
  const _CompletedMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white.withValues(alpha: .045)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94AEC5),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -.5,
          ),
        ),
      ],
    ),
  );
}

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: rizeCyan));
  }
}

class HomeErrorView extends StatelessWidget {
  const HomeErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: RizeCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white70,
                size: 38,
              ),
              const SizedBox(height: 14),
              const Text(
                'Das hat nicht geklappt',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.58)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Principle {
  const _Principle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
