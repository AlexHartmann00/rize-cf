import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/rize_card.dart';

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
                const Text('🔥', style: TextStyle(fontSize: 15)),
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
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -24,
            top: -34,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rizeCyan.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                'Dein Daily Spin',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Eine Übung. Deine Intensität. Ein klarer Impuls für heute.',
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
                  'HEUTIGES WORKOUT ZIEHEN',
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

class CompletedWorkoutHero extends StatelessWidget {
  const CompletedWorkoutHero({
    super.key,
    required this.workout,
    required this.streak,
    required this.nextWorkoutIn,
  });

  final ScheduledWorkout workout;
  final int streak;
  final String nextWorkoutIn;

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      accentColor: rizeGreen,
      child: Column(
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: rizeGreen.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: rizeGreen.withOpacity(0.34), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: rizeGreen, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            'Für heute geschafft!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            workout.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _CompletedMetric(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak Tage',
                  label: 'Aktuelle Serie',
                  color: const Color(0xFFFF9857),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompletedMetric(
                  icon: Icons.bolt_rounded,
                  value: workout.impactScore.toStringAsFixed(2),
                  label: 'Impact',
                  color: rizeCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dein nächster Daily Spin ist in $nextWorkoutIn bereit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.47),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
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
