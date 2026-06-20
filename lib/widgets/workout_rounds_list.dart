import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:rize/pages/workout_execution_page.dart';
import 'package:rize/types/workout.dart';

class WorkoutRoundsList extends StatefulWidget {
  const WorkoutRoundsList({super.key, required this.workout});

  final ScheduledWorkout workout;

  @override
  State<WorkoutRoundsList> createState() => _WorkoutRoundsListState();
}

class _WorkoutRoundsListState extends State<WorkoutRoundsList> {
  @override
  Widget build(BuildContext context) {
    final int completedCount = widget.workout.schedule
        .where((WorkoutStep step) => step.completedUnits >= step.plannedUnits)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'DEINE RUNDEN',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$completedCount / ${widget.workout.schedule.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...widget.workout.schedule.indexed.map(
          ((int, WorkoutStep) entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.$1 == widget.workout.schedule.length - 1 ? 0 : 8,
            ),
            child: _RoundTile(
              index: entry.$1,
              workout: widget.workout,
              step: entry.$2,
              onStart: () => _startRound(entry.$2, entry.$1),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startRound(WorkoutStep step, int index) async {
    if (step.timeOfDay != TimeOfDay.any && !_timeIsValid(step.timeOfDay)) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Nicht im richtigen Zeitraum'),
          content: Text(
            'Diese Runde ist für ${_timeLabel(step.timeOfDay)} vorgesehen.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final bool? completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutExecutionPage(
          workout: widget.workout,
          scheduleEntryIndex: index,
        ),
      ),
    );
    if (completed == true && mounted) setState(() {});
  }

  bool _timeIsValid(TimeOfDay value) {
    final int hour = DateTime.now().hour;
    return switch (value) {
      TimeOfDay.morning => hour >= 5 && hour < 12,
      TimeOfDay.afternoon => hour >= 12 && hour < 17,
      TimeOfDay.evening => hour >= 17 && hour < 22,
      TimeOfDay.any => true,
    };
  }
}

class _RoundTile extends StatelessWidget {
  const _RoundTile({
    required this.index,
    required this.workout,
    required this.step,
    required this.onStart,
  });

  final int index;
  final ScheduledWorkout workout;
  final WorkoutStep step;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final bool completed = step.completedUnits >= step.plannedUnits;
    final String target = workout.workoutType == WorkoutType.dynamic
        ? '${(workout.baseReps ?? 0) * workout.intensityFactor} Wiederholungen'
        : '${(workout.baseSeconds ?? 0) * workout.intensityFactor} Sekunden';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF49D890).withOpacity(0.12)
            : Colors.white.withOpacity(0.065),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed
              ? const Color(0xFF49D890).withOpacity(0.34)
              : Colors.white.withOpacity(0.09),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF49D890)
                  : const Color(0xFF58C7F5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 21)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF7ED8FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  completed ? 'Runde geschafft' : 'Runde ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.timeOfDay == TimeOfDay.any
                      ? target
                      : '$target · ${_timeLabel(step.timeOfDay)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.54),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            height: 38,
            child: completed
                ? const Center(
                    child: Text(
                      'FERTIG',
                      style: TextStyle(
                        color: Color(0xFF63E3A4),
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF125EB4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _timeLabel(TimeOfDay value) => switch (value) {
  TimeOfDay.morning => 'morgens',
  TimeOfDay.afternoon => 'nachmittags',
  TimeOfDay.evening => 'abends',
  TimeOfDay.any => 'jederzeit',
};
