import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/rize_card.dart';

class WorkoutDetailsHero extends StatelessWidget {
  const WorkoutDetailsHero({
    super.key,
    required this.workout,
    required this.onBack,
  });

  final Workout workout;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bool isStatic = workout.workoutType == WorkoutType.static;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: rizeCardDecoration(accentColor: rizeCyan, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isStatic
                          ? Icons.pause_circle_outline_rounded
                          : Icons.repeat_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isStatic ? 'Zeit' : 'Wiederholungen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            workout.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _HeroPill(
                icon: Icons.bolt_rounded,
                label: 'Intensität ${_impactLabel(workout.impactLevel)}',
                color: _impactColor(workout.impactScore),
              ),
              if (workout.isUnilateral)
                const _HeroPill(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Beidseitig ausführen',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkoutDetailsSection extends StatelessWidget {
  const WorkoutDetailsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: rizeCyan.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: rizeCyan, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.52),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class WorkoutDetailsBodyText extends StatelessWidget {
  const WorkoutDetailsBodyText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.76),
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class UnilateralWorkoutCard extends StatelessWidget {
  const UnilateralWorkoutCard({super.key, required this.helpText});

  final String? helpText;

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      accentColor: const Color(0xFFFFC857),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Einseitige Übung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Diese Übung wird erst vollständig auf der linken und danach '
            'auf der rechten Seite ausgeführt.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helpText != null && helpText!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                helpText!.trim(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                  height: 1.45,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CoachingCueList extends StatelessWidget {
  const CoachingCueList({super.key, required this.coachingCues});

  final String coachingCues;

  @override
  Widget build(BuildContext context) {
    return Text(
      coachingCues.trim(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.78),
        height: 1.5,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class WorkoutDetailsBottomAction extends StatelessWidget {
  const WorkoutDetailsBottomAction({
    super.key,
    required this.workout,
    required this.onStart,
  });

  final Workout workout;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final bool canStart = workout is ScheduledWorkout;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF13345C).withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: canStart ? onStart : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.white,
          foregroundColor: rizeBlue,
          disabledBackgroundColor: Colors.white.withOpacity(0.16),
          disabledForegroundColor: Colors.white.withOpacity(0.52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: Icon(
          canStart ? Icons.play_arrow_rounded : Icons.info_outline_rounded,
        ),
        label: Text(
          canStart ? 'WORKOUT STARTEN' : 'AUS DER TAGESPLANUNG STARTEN',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.25,
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _impactColor(double score) {
  final double normalized = score.clamp(0.0, 1.0);

  if (normalized <= 0.5) {
    return Color.lerp(
          const Color(0xFF42D77D),
          const Color(0xFFFFC857),
          normalized * 2,
        ) ??
        const Color(0xFF42D77D);
  }

  return Color.lerp(
        const Color(0xFFFFC857),
        const Color(0xFFFF5968),
        (normalized - 0.5) * 2,
      ) ??
      const Color(0xFFFF5968);
}

String _impactLabel(ImpactLevel level) => switch (level) {
  ImpactLevel.low => 'niedrig',
  ImpactLevel.medium => 'mittel',
  ImpactLevel.high => 'hoch',
};
