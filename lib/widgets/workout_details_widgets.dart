
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
    final Color impactColor = _impactColor(workout.impactScore);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF63C6F3),
            Color(0xFF176BC7),
            Color(0xFF0A3F8F),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
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
                      isStatic ? 'Statisch' : 'Dynamisch',
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
                icon: Icons.schedule_rounded,
                label: workout.durationString,
              ),
              _HeroPill(
                icon: Icons.bolt_rounded,
                label:
                    'Impact ${workout.impactScore.toStringAsFixed(2)}',
                color: impactColor,
              ),
              if (workout.isUnilateral)
                const _HeroPill(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Beidseitig ausführen',
                ),
            ],
          ),
          if (workout.usedMuscleGroups.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              workout.usedMuscleGroups.join(' · '),
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
                child: Icon(
                  icon,
                  color: rizeCyan,
                  size: 21,
                ),
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
  const WorkoutDetailsBodyText({
    super.key,
    required this.text,
  });

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
  const UnilateralWorkoutCard({
    super.key,
    required this.helpText,
  });

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
  const CoachingCueList({
    super.key,
    required this.coachingCues,
  });

  final String coachingCues;

  @override
  Widget build(BuildContext context) {
    final List<String> cues = _splitCues(coachingCues);

    return Column(
      children: cues.asMap().entries.map(
        (MapEntry<int, String> entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == cues.length - 1 ? 0 : 10,
            ),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: rizeCyan.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: rizeCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        height: 1.4,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).toList(growable: false),
    );
  }

  List<String> _splitCues(String value) {
    final List<String> parts = value
        .split(RegExp(r'[\n•;]+'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    return parts.isEmpty ? <String>[value] : parts;
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
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
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
          canStart
              ? Icons.play_arrow_rounded
              : Icons.info_outline_rounded,
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
  const _HeroPill({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: foreground,
          ),
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
