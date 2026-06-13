import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets.dart';
import 'package:rize/youtube.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WorkoutExecutionPage extends StatelessWidget {
  final ScheduledWorkout workout;
  final int scheduleEntryIndex;

  const WorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (workout.workoutType == WorkoutType.dynamic) {
      return DynamicWorkoutExecutionPage(
        workout: workout,
        scheduleEntryIndex: scheduleEntryIndex,
      );
    }

    return StaticWorkoutExecutionPage(
      workout: workout,
      scheduleEntryIndex: scheduleEntryIndex,
    );
  }
}

class WorkoutExecutionHeader extends StatelessWidget {
  final ScheduledWorkout workout;
  final int scheduleEntryIndex;

  const WorkoutExecutionHeader({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  @override
  Widget build(BuildContext context) {
    final int maxReps =
        (workout.baseReps ?? 0) * workout.intensityFactor;

    final int seconds =
        (workout.baseSeconds ?? 0) * workout.intensityFactor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          workout.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 50,
            
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            const Icon(Icons.flag_circle, color: Colors.white),
            Text(
              (scheduleEntryIndex + 1).toString(),
              style: const TextStyle(color: Colors.white, fontSize: 30),
            ),
            const SizedBox(width: 5),
            Icon(
              workout.workoutType == WorkoutType.dynamic
                  ? Icons.repeat
                  : Icons.timer,
              color: Colors.white,
            ),
            Text(
              workout.workoutType == WorkoutType.dynamic
                  ? maxReps.toString()
                  : seconds.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 30),
            ),
          ],
        ),
        if (workout.videoExplanationUrl != null &&
            workout.videoExplanationUrl!.contains('yout'))
          Padding(
            padding: const EdgeInsets.all(8),
            child: YoutubeVideo(
              videoId: workout.youtubeVideoId,
            ),
          ),
      ],
    );
  }
}

class StaticWorkoutExecutionPage extends StatefulWidget {
  final ScheduledWorkout workout;
  final int scheduleEntryIndex;

  const StaticWorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  @override
  State<StaticWorkoutExecutionPage> createState() =>
      _StaticWorkoutExecutionPageState();
}

class _StaticWorkoutExecutionPageState
    extends State<StaticWorkoutExecutionPage> {

  bool showTimer = false;
  bool timerCompleted = false;
  int timerSeconds = 0;

  int get totalSeconds =>
      (widget.workout.baseSeconds ?? 0) *
      widget.workout.intensityFactor;

  Future<void> startTimer() async {
    WakelockPlus.enable();

    setState(() {
      showTimer = true;
      timerSeconds = totalSeconds;
    });

    while (mounted && timerSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      setState(() => timerSeconds--);
    }

    HapticFeedback.vibrate();

    setState(() {
      showTimer = false;
      timerCompleted = true;
    });
  }

  Future<void> finishRound() async {
    WakelockPlus.disable();

    final workoutStep =
        widget.workout.schedule[widget.scheduleEntryIndex];

    widget.workout.schedule[widget.scheduleEntryIndex] =
        WorkoutStep(
      timeOfDay: workoutStep.timeOfDay,
      plannedUnits: workoutStep.plannedUnits,
      completedUnits: workoutStep.plannedUnits,
    );

    await uploadWorkoutToServer(widget.workout);

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          WorkoutExecutionHeader(
            workout: widget.workout,
            scheduleEntryIndex: widget.scheduleEntryIndex,
          ),

          Expanded(child: SizedBox(),),

          if (!showTimer && !timerCompleted)
            IconButton(onPressed: startTimer, icon: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.play_arrow, color: Colors.blue),
                ),
                Text('Timer starten', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30)),
              ],
            )),
            
          
          if (showTimer)
            WorkoutTimerIndicator(
              remainingSeconds: timerSeconds,
              totalSeconds: totalSeconds,
            ),

          if (timerCompleted)
            FinishButton(onPressed: finishRound),

          SizedBox(height: 50),
        ],
      ),
    );
  }
}

class WorkoutTimerIndicator extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const WorkoutTimerIndicator({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        1 - (totalSeconds == 0 ? 0.0 : remainingSeconds / totalSeconds);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Background ring
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              color: Colors.white,
            ),
          ),

          /// Progress ring
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              strokeCap: StrokeCap.round, // rounded edges ✅
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),

          /// Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remainingSeconds.toString(),
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Sekunden",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class DynamicWorkoutExecutionPage extends StatefulWidget {
  final ScheduledWorkout workout;
  final int scheduleEntryIndex;

  const DynamicWorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  @override
  State<DynamicWorkoutExecutionPage> createState() =>
      _DynamicWorkoutExecutionPageState();
}

class _DynamicWorkoutExecutionPageState
    extends State<DynamicWorkoutExecutionPage> {

  int managedRepetitions = 0;

  int get maxReps =>
      (widget.workout.baseReps ?? 0) *
      widget.workout.intensityFactor;

  Future<void> finishRound() async {
    final completed = managedRepetitions >= maxReps;

    final workoutStep =
        widget.workout.schedule[widget.scheduleEntryIndex];

    widget.workout.schedule[widget.scheduleEntryIndex] =
        WorkoutStep(
      timeOfDay: workoutStep.timeOfDay,
      plannedUnits: workoutStep.plannedUnits,
      completedUnits:
          completed ? workoutStep.plannedUnits : 0,
    );

    await uploadWorkoutToServer(widget.workout);

    Navigator.of(context).pop(completed);
  }

  @override
  Widget build(BuildContext context) {
    return RizeScaffold(
      appBar: rizeAppBar,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          WorkoutExecutionHeader(
            workout: widget.workout,
            scheduleEntryIndex: widget.scheduleEntryIndex,
          ),

          NumberPicker(
            axis: Axis.vertical,
            value: managedRepetitions.clamp(0, maxReps),
            minValue: 0,
            maxValue: maxReps,
            itemHeight: 50,
            itemWidth: 90,
            step: 1,
            haptics: true,
            selectedTextStyle: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.45),
            ),
            onChanged: (v) =>
                setState(() => managedRepetitions = v),
          ),

          const Text(
            'Wiederholungen geschafft',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          FinishButton(onPressed: finishRound),
        ],
      ),
    );
  }
}

class FinishButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FinishButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Runde abschließen',
              style: TextStyle(
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }
}