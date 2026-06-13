
import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/helpers/workout_execution_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/rize_card.dart';

class WorkoutExecutionTopBar extends StatelessWidget {
  const WorkoutExecutionTopBar({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
    required this.onClose,
  });

  final ScheduledWorkout workout;
  final int scheduleEntryIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.08),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.close_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                workout.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Einheit ${scheduleEntryIndex + 1} · '
                '${workoutTypeLabel(workout.workoutType)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.52),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: rizeCyan.withOpacity(0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(
            workoutTypeIcon(workout.workoutType),
            color: rizeCyan,
            size: 21,
          ),
        ),
      ],
    );
  }
}

class WorkoutReadyCard extends StatelessWidget {
  const WorkoutReadyCard({
    super.key,
    required this.workout,
    required this.target,
    required this.onStart,
    this.video,
  });

  final ScheduledWorkout workout;
  final int target;
  final VoidCallback onStart;
  final Widget? video;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RizeCard(
          accentColor: rizeCyan,
          child: Column(
            children: <Widget>[
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[rizeCyan, rizeBlue],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: rizeBlue.withOpacity(0.32),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  workoutTypeIcon(workout.workoutType),
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Bereit für Deine Runde?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                workout.workoutType == WorkoutType.dynamic
                    ? '$target Wiederholungen – tippe während der Übung einfach auf den Bildschirm.'
                    : '$target Sekunden – der Timer läuft für Dich mit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.white,
                  foregroundColor: rizeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'RUNDE STARTEN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (video != null) ...<Widget>[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: video!,
          ),
        ],
      ],
    );
  }
}

class WorkoutCountdownView extends StatelessWidget {
  const WorkoutCountdownView({
    super.key,
    required this.value,
  });

  final int value;

  @override
  Widget build(BuildContext context) {
    final String label = value > 0 ? '$value' : 'LOS!';

    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(value),
        tween: Tween<double>(begin: 0.65, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double scale, Widget? child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[rizeCyan, rizeBlue],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: rizeBlue.withOpacity(0.40),
                    blurRadius: 42,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: value > 0 ? 88 : 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DynamicRepControl extends StatelessWidget {
  const DynamicRepControl({
    super.key,
    required this.current,
    required this.target,
    required this.paused,
    required this.onIncrement,
    required this.onDecrement,
    required this.onPauseToggle,
    required this.onFinishEarly,
  });

  final int current;
  final int target;
  final bool paused;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onPauseToggle;
  final VoidCallback onFinishEarly;

  @override
  Widget build(BuildContext context) {
    final double progress = workoutExecutionProgress(
      current: current,
      target: target,
    );

    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: paused ? null : onIncrement,
            onVerticalDragEnd: paused
                ? null
                : (DragEndDetails details) {
                    if ((details.primaryVelocity ?? 0) > 200) {
                      onDecrement();
                    } else {
                      onIncrement();
                    }
                  },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ProgressArcPainter(
                        progress: progress,
                        color: rizeCyan,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            '$current',
                            key: ValueKey<int>(current),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 112,
                              height: 0.9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'von $target Wiederholungen',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            paused
                                ? 'Pausiert'
                                : 'Tippen = +1 · nach unten wischen = −1',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        WorkoutExecutionControls(
          paused: paused,
          onPauseToggle: onPauseToggle,
          onUndo: current > 0 ? onDecrement : null,
          onFinishEarly: onFinishEarly,
        ),
      ],
    );
  }
}

class StaticTimerControl extends StatelessWidget {
  const StaticTimerControl({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.paused,
    required this.onPauseToggle,
    required this.onFinishEarly,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool paused;
  final VoidCallback onPauseToggle;
  final VoidCallback onFinishEarly;

  @override
  Widget build(BuildContext context) {
    final int completed = totalSeconds - remainingSeconds;
    final double progress = workoutExecutionProgress(
      current: completed,
      target: totalSeconds,
    );

    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 16,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      strokeCap: StrokeCap.round,
                      color: rizeCyan,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Colors.white.withOpacity(0.13),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: rizeBlue.withOpacity(0.14),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          formatExecutionTime(remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 76,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          paused ? 'PAUSIERT' : 'NOCH ZU HALTEN',
                          style: TextStyle(
                            color: paused
                                ? const Color(0xFFFFC857)
                                : Colors.white.withOpacity(0.52),
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        WorkoutExecutionControls(
          paused: paused,
          onPauseToggle: onPauseToggle,
          onFinishEarly: onFinishEarly,
        ),
      ],
    );
  }
}

class WorkoutExecutionControls extends StatelessWidget {
  const WorkoutExecutionControls({
    super.key,
    required this.paused,
    required this.onPauseToggle,
    required this.onFinishEarly,
    this.onUndo,
  });

  final bool paused;
  final VoidCallback onPauseToggle;
  final VoidCallback onFinishEarly;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onUndo != null) ...<Widget>[
          IconButton.filledTonal(
            tooltip: 'Letzte Wiederholung zurücknehmen',
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: onPauseToggle,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              backgroundColor: Colors.white,
              foregroundColor: rizeBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(
              paused ? 'WEITERMACHEN' : 'PAUSE',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Runde vorzeitig beenden',
          onPressed: onFinishEarly,
          icon: const Icon(Icons.stop_rounded),
        ),
      ],
    );
  }
}

class WorkoutCompletionView extends StatelessWidget {
  const WorkoutCompletionView({
    super.key,
    required this.workout,
    required this.onConfirm,
    required this.saving,
  });

  final ScheduledWorkout workout;
  final VoidCallback onConfirm;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RizeCard(
        accentColor: rizeGreen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.3, end: 1),
              duration: const Duration(milliseconds: 850),
              curve: Curves.elasticOut,
              builder: (
                BuildContext context,
                double scale,
                Widget? child,
              ) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: rizeGreen.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rizeGreen.withOpacity(0.38),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: rizeGreen.withOpacity(0.20),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: rizeGreen,
                  size: 58,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              completionHeadline(workout),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              completionMessage(workout),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.bolt_rounded,
                    color: rizeCyan,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Impact ${workout.impactScore.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: saving ? null : onConfirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.white,
                foregroundColor: rizeBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                saving ? 'WIRD GESPEICHERT …' : 'ERFOLG VERBUCHEN',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutExecutionErrorView extends StatelessWidget {
  const WorkoutExecutionErrorView({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RizeCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.white70,
              size: 40,
            ),
            const SizedBox(height: 14),
            const Text(
              'Speichern nicht möglich',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deine Runde bleibt geöffnet. Prüfe kurz Deine Verbindung '
              'und versuche es erneut.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Erneut speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  const _ProgressArcPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(
      22,
      22,
      size.width - 44,
      size.height - 44,
    );

    final Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.06);

    final Paint foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, -1.57, 6.28, false, background);
    canvas.drawArc(rect, -1.57, 6.28 * progress, false, foreground);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
