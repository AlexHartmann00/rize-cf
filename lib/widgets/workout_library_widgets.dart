import 'package:flutter/material.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/pages/workout_details_page.dart';
import 'package:rize/types/workout.dart';

class WorkoutLibrarySearchField extends StatelessWidget {
  const WorkoutLibrarySearchField({
    super.key,
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        hintText: 'Workouts oder Muskelgruppen suchen',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.52),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.white.withOpacity(0.72),
        ),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: hasQuery
              ? IconButton(
                  key: const ValueKey<String>('clear'),
                  tooltip: 'Suche löschen',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : const SizedBox.shrink(key: ValueKey<String>('empty')),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class WorkoutLibraryHeader extends StatelessWidget {
  const WorkoutLibraryHeader({
    super.key,
    required this.visibleWorkoutCount,
    required this.totalWorkoutCount,
    required this.isSearching,
  });

  final int visibleWorkoutCount;
  final int totalWorkoutCount;
  final bool isSearching;

  @override
  Widget build(final BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String countLabel = isSearching
        ? '$visibleWorkoutCount von $totalWorkoutCount gefunden'
        : '$totalWorkoutCount Workouts';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Workout-Bibliothek',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Finde die passende Übung für Dein Training.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.62),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Text(
            countLabel,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class WorkoutLibraryEmptyState extends StatelessWidget {
  const WorkoutLibraryEmptyState({
    super.key,
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 35,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Keine Workouts gefunden',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Für „$query“ gibt es aktuell keinen Treffer. '
                'Versuche einen anderen Namen oder eine Muskelgruppe.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Suche zurücksetzen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutSummaryWidget extends StatelessWidget {
  const WorkoutSummaryWidget({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = workout.impactScore.clamp(0.0, 1.0);
    final impactColor = workoutImpactColor(score);
    final isStatic = workout.workoutType == WorkoutType.static;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkoutDetailsPage(workout: workout),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.07),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _WorkoutIcon(isStatic: isStatic),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                workout.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _InfoPill(
                                    icon: isStatic
                                        ? Icons.timer_outlined
                                        : Icons.repeat_rounded,
                                    label: isStatic ? 'Statisch' : 'Dynamisch',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: Colors.white.withOpacity(0.72),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _CompactImpactBar(
                      score: score,
                      impactColor: impactColor,
                      level: workout.impactLevel.name,
                    ),
                    if (workout.usedMuscleGroups.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      _MuscleGroupSummary(
                        groups: workout.usedMuscleGroups
                            .map((group) => muscleGroupLabel(group.toString()))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutIcon extends StatelessWidget {
  const _WorkoutIcon({required this.isStatic});

  final bool isStatic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF79D5FF), Color(0xFF1670D2)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1670D2).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        isStatic ? Icons.timer_outlined : Icons.repeat_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _CompactImpactBar extends StatelessWidget {
  const _CompactImpactBar({
    required this.score,
    required this.impactColor,
    required this.level,
  });

  final double score;
  final Color impactColor;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.13),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: impactColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt_rounded, color: impactColor, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Intensität ${workoutImpactLevelLabel(level)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                score.toStringAsFixed(2),
                style: TextStyle(
                  color: impactColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(impactColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupSummary extends StatelessWidget {
  const _MuscleGroupSummary({required this.groups});

  final List<String> groups;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = groups.take(3).toList();
    final hiddenCount = groups.length - visibleGroups.length;

    return Row(
      children: <Widget>[
        Icon(
          Icons.accessibility_new_rounded,
          size: 17,
          color: Colors.white.withOpacity(0.56),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            visibleGroups.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (hiddenCount > 0)
          Text(
            '+$hiddenCount',
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.72)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTypeIcon extends StatelessWidget {
  const _WorkoutTypeIcon({required this.isStatic, required this.accentColor});

  final bool isStatic;
  final Color accentColor;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Icon(
        isStatic ? Icons.timer_outlined : Icons.repeat_rounded,
        color: accentColor,
        size: 24,
      ),
    );
  }
}

class _WorkoutPropertyChip extends StatelessWidget {
  const _WorkoutPropertyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutImpactSection extends StatelessWidget {
  const _WorkoutImpactSection({
    required this.score,
    required this.level,
    required this.color,
  });

  final double score;
  final String level;
  final Color color;

  @override
  Widget build(final BuildContext context) {
    final String formattedScore = score.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: score,
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                Icon(Icons.bolt_rounded, size: 18, color: color),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Trainingsintensität',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.52),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  workoutImpactLevelLabel(level),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formattedScore,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Impact',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.48),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupChip extends StatelessWidget {
  const _MuscleGroupChip({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color workoutImpactColor(final double score) {
  final double normalizedScore = score.clamp(0.0, 1.0);

  if (normalizedScore <= 0.5) {
    return Color.lerp(
          const Color(0xFF42D77D),
          const Color(0xFFFFC857),
          normalizedScore * 2,
        ) ??
        const Color(0xFF42D77D);
  }

  return Color.lerp(
        const Color(0xFFFFC857),
        const Color(0xFFFF5C6C),
        (normalizedScore - 0.5) * 2,
      ) ??
      const Color(0xFFFF5C6C);
}

String workoutImpactLevelLabel(final String level) {
  switch (level.toLowerCase()) {
    case 'low':
      return 'Niedrig';
    case 'medium':
      return 'Mittel';
    case 'high':
      return 'Hoch';
    default:
      return level;
  }
}
