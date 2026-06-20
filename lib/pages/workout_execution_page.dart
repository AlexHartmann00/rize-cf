import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/firestore.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/helpers/workout_execution_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/rize_card.dart';
import 'package:rize/widgets/workout_execution_widgets.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/widgets/milestone_widgets.dart';
import 'package:rize/youtube.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WorkoutExecutionPage extends StatefulWidget {
  const WorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.scheduleEntryIndex,
  });

  final ScheduledWorkout workout;
  final int scheduleEntryIndex;

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  WorkoutExecutionPhase _phase = WorkoutExecutionPhase.ready;
  WorkoutExecutionSide _currentSide = WorkoutExecutionSide.left;

  Timer? _timer;
  int _countdownValue = 3;
  int _currentValue = 0;
  int _remainingSeconds = 0;
  bool _saving = false;

  int get _target => workoutTargetValue(widget.workout);

  bool get _isDynamic => widget.workout.workoutType == WorkoutType.dynamic;

  bool get _isUnilateral => widget.workout.isUnilateral;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _target;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    if (_phase != WorkoutExecutionPhase.ready &&
        _phase != WorkoutExecutionPhase.sideTransition) {
      return;
    }

    await WakelockPlus.enable();
    await HapticFeedback.mediumImpact();

    setState(() {
      _phase = WorkoutExecutionPhase.countdown;
      _countdownValue = 3;
    });

    for (int value = 3; value >= 1; value--) {
      if (!mounted || _phase != WorkoutExecutionPhase.countdown) return;

      setState(() => _countdownValue = value);
      await HapticFeedback.selectionClick();
      await Future<void>.delayed(const Duration(milliseconds: 850));
    }

    if (!mounted) return;

    setState(() {
      _countdownValue = 0;
      _phase = WorkoutExecutionPhase.active;
    });

    await HapticFeedback.heavyImpact();

    if (!_isDynamic) {
      _startStaticTimer();
    }
  }

  void _startStaticTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (!mounted || _phase != WorkoutExecutionPhase.active) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        await SystemSound.play(SystemSoundType.alert);
        await _completeCurrentSubStep();
        return;
      }

      setState(() => _remainingSeconds -= 1);

      if (_remainingSeconds <= 3) {
        await HapticFeedback.mediumImpact();
      } else if (_remainingSeconds % 5 == 0) {
        await HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _incrementRep() async {
    if (_phase != WorkoutExecutionPhase.active || !_isDynamic) return;

    final int next = (_currentValue + 1).clamp(0, _target);
    setState(() => _currentValue = next);

    if (next >= _target) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _completeCurrentSubStep();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> _decrementRep() async {
    if (!_isDynamic || _currentValue <= 0) return;

    setState(() => _currentValue -= 1);
    await HapticFeedback.lightImpact();
  }

  void _setRepValue(int value) {
    if (_phase != WorkoutExecutionPhase.active || !_isDynamic) return;
    setState(() => _currentValue = value);
    HapticFeedback.selectionClick();
  }

  Future<void> _completeCurrentSubStep() async {
    _timer?.cancel();
    if (!mounted) return;

    if (_isUnilateral && _currentSide == WorkoutExecutionSide.left) {
      setState(() => _phase = WorkoutExecutionPhase.sideTransition);
      await HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _phase = WorkoutExecutionPhase.completed;
      if (!_isDynamic) {
        _remainingSeconds = 0;
      }
    });

    await HapticFeedback.heavyImpact();
  }

  Future<void> _startSecondSide() async {
    setState(() {
      _currentSide = WorkoutExecutionSide.right;
      _currentValue = 0;
      _remainingSeconds = _target;
    });

    await _startCountdown();
  }

  Future<void> _togglePause() async {
    if (_phase == WorkoutExecutionPhase.active) {
      setState(() => _phase = WorkoutExecutionPhase.paused);
      await HapticFeedback.lightImpact();
      return;
    }

    if (_phase == WorkoutExecutionPhase.paused) {
      setState(() => _phase = WorkoutExecutionPhase.active);
      await HapticFeedback.mediumImpact();

      if (!_isDynamic) _startStaticTimer();
    }
  }

  Future<void> _requestFinishEarly() async {
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF15375F),
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.flag_outlined,
                  color: Colors.white70,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Runde wirklich beenden?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isUnilateral
                      ? 'Die Runde zählt nur, wenn beide Seiten vollständig abgeschlossen wurden.'
                      : 'Nur vollständig absolvierte Runden werden als abgeschlossen gewertet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Weitermachen'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Beenden'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      _timer?.cancel();
      await WakelockPlus.disable();
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  Future<void> _requestClose() async {
    if (_phase == WorkoutExecutionPhase.ready ||
        _phase == WorkoutExecutionPhase.completed ||
        _phase == WorkoutExecutionPhase.error) {
      await WakelockPlus.disable();
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    await _requestFinishEarly();
  }

  Future<void> _saveCompletedRound() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _phase = WorkoutExecutionPhase.saving;
    });

    try {
      final WorkoutStep currentStep =
          widget.workout.schedule[widget.scheduleEntryIndex];

      widget.workout.schedule[widget.scheduleEntryIndex] = completedWorkoutStep(
        currentStep,
        actualValue: _isDynamic ? _currentValue : _target,
      );

      await uploadWorkoutToServer(widget.workout);
      List<MilestoneState> milestones = const <MilestoneState>[];
      try {
        milestones = await evaluateAndClaimMilestones();
      } catch (error) {
        debugPrint('Milestone evaluation failed: $error');
      }
      await WakelockPlus.disable();

      if (!mounted) return;
      await showMilestoneCelebration(context, milestones);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _phase = WorkoutExecutionPhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase == WorkoutExecutionPhase.ready,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) await _requestClose();
      },
      child: RizeScaffold(
        appBar: null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: <Widget>[
                WorkoutExecutionTopBar(
                  workout: widget.workout,
                  scheduleEntryIndex: widget.scheduleEntryIndex,
                  onClose: _requestClose,
                ),
                if (_isUnilateral) ...<Widget>[
                  const SizedBox(height: 10),
                  _SideProgressHeader(
                    side: _currentSide,
                    secondSideReached:
                        _currentSide == WorkoutExecutionSide.right ||
                        _phase == WorkoutExecutionPhase.completed ||
                        _phase == WorkoutExecutionPhase.saving,
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(child: _buildPhaseContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case WorkoutExecutionPhase.ready:
        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              if (_isUnilateral &&
                  widget.workout.unilateralHelpText != null &&
                  widget.workout.unilateralHelpText!
                      .trim()
                      .isNotEmpty) ...<Widget>[
                _UnilateralHelpCard(
                  text: widget.workout.unilateralHelpText!.trim(),
                ),
                const SizedBox(height: 14),
              ],
              WorkoutReadyCard(
                workout: widget.workout,
                target: _target,
                onStart: _startCountdown,
                video: _buildVideo(),
              ),
            ],
          ),
        );

      case WorkoutExecutionPhase.countdown:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isUnilateral) ...<Widget>[
              _SideBadge(side: _currentSide),
              const SizedBox(height: 18),
            ],
            WorkoutCountdownView(value: _countdownValue),
          ],
        );

      case WorkoutExecutionPhase.sideTransition:
        return _SideTransitionCard(
          helpText: widget.workout.unilateralHelpText,
          onContinue: _startSecondSide,
        );

      case WorkoutExecutionPhase.active:
      case WorkoutExecutionPhase.paused:
        return Column(
          children: <Widget>[
            if (_isUnilateral) ...<Widget>[
              _SideBadge(side: _currentSide),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _isDynamic
                  ? DynamicRepControl(
                      current: _currentValue,
                      target: _target,
                      paused: _phase == WorkoutExecutionPhase.paused,
                      onIncrement: _incrementRep,
                      onChanged: _setRepValue,
                      onDecrement: _decrementRep,
                      onPauseToggle: _togglePause,
                      onFinishEarly: _completeCurrentSubStep,
                    )
                  : StaticTimerControl(
                      remainingSeconds: _remainingSeconds,
                      totalSeconds: _target,
                      paused: _phase == WorkoutExecutionPhase.paused,
                      onPauseToggle: _togglePause,
                      onFinishEarly: _requestFinishEarly,
                    ),
            ),
          ],
        );

      case WorkoutExecutionPhase.completed:
      case WorkoutExecutionPhase.saving:
        return WorkoutCompletionView(
          workout: widget.workout,
          saving: _saving,
          onConfirm: _saveCompletedRound,
        );

      case WorkoutExecutionPhase.error:
        return WorkoutExecutionErrorView(onRetry: _saveCompletedRound);
    }
  }

  Widget? _buildVideo() {
    final String? url = widget.workout.videoExplanationUrl;
    if (url == null || !url.contains('yout')) return null;

    return YoutubeVideo(videoId: widget.workout.youtubeVideoId);
  }
}

class _SideProgressHeader extends StatelessWidget {
  const _SideProgressHeader({
    required this.side,
    required this.secondSideReached,
  });

  final WorkoutExecutionSide side;
  final bool secondSideReached;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SideStep(
            label: 'Links',
            active: side == WorkoutExecutionSide.left,
            completed: secondSideReached,
          ),
        ),
        Container(width: 28, height: 2, color: Colors.white.withOpacity(0.14)),
        Expanded(
          child: _SideStep(
            label: 'Rechts',
            active: side == WorkoutExecutionSide.right,
            completed: false,
          ),
        ),
      ],
    );
  }
}

class _SideStep extends StatelessWidget {
  const _SideStep({
    required this.label,
    required this.active,
    required this.completed,
  });

  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final Color color = completed
        ? rizeGreen
        : active
        ? rizeCyan
        : Colors.white.withOpacity(0.32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            completed ? Icons.check_rounded : Icons.circle_outlined,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBadge extends StatelessWidget {
  const _SideBadge({required this.side});

  final WorkoutExecutionSide side;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: rizeCyan.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: rizeCyan.withOpacity(0.24)),
      ),
      child: Text(
        workoutSideLabel(side).toUpperCase(),
        style: const TextStyle(
          color: rizeCyan,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UnilateralHelpCard extends StatelessWidget {
  const _UnilateralHelpCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RizeCard(
      accentColor: rizeCyan,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.swap_horiz_rounded, color: rizeCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Einseitige Übung',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTransitionCard extends StatelessWidget {
  const _SideTransitionCard({required this.onContinue, this.helpText});

  final VoidCallback onContinue;
  final String? helpText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RizeCard(
        accentColor: rizeCyan,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: rizeGreen.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: rizeGreen.withOpacity(0.34),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: rizeGreen,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Linke Seite geschafft',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jetzt neu positionieren und anschließend die rechte Seite absolvieren.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.45,
              ),
            ),
            if (helpText != null && helpText!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: rizeCyan.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  helpText!.trim(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.white,
                foregroundColor: rizeBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text(
                'MIT RECHTS WEITERMACHEN',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
