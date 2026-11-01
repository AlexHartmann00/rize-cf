import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rize/helpers/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void>? _celebrationTail;

/// One queue for milestones, level-ups and comebacks: dialogs never overlap.
Future<void> queueWorkoutCelebration(
  BuildContext context,
  Future<void> Function() action,
) {
  final previous = _celebrationTail;
  Future<void> run() async {
    if (context.mounted) await action();
  }

  final operation = previous == null
      ? Future<void>.sync(run)
      : previous.then((_) => run());
  late final Future<void> pending;
  pending = operation
      .catchError((Object error) {
        debugPrint('Celebration failed: $error');
      })
      .whenComplete(() {
        if (identical(_celebrationTail, pending)) _celebrationTail = null;
      });
  _celebrationTail = pending;
  return pending;
}

enum ProgressCelebrationKind { levelUp, comeback }

Future<void> showProgressCelebration(
  BuildContext context, {
  required ProgressCelebrationKind kind,
  String? previousLevel,
  String? nextLevel,
  int inactiveDays = 3,
  String? storageKey,
}) => queueWorkoutCelebration(context, () async {
  final userId = authServiceNotifier.value.currentUser?.uid;
  if (userId == null) return;
  final preferences = await SharedPreferences.getInstance();
  final key = storageKey == null ? null : 'celebration_${userId}_$storageKey';
  if (key != null && preferences.getBool(key) == true) return;
  if (!context.mounted) return;
  final acknowledged = await presentProgressCelebration(
    context,
    kind: kind,
    previousLevel: previousLevel,
    nextLevel: nextLevel,
    inactiveDays: inactiveDays,
  );
  if (acknowledged == true && key != null) await preferences.setBool(key, true);
});

Future<bool?> presentProgressCelebration(
  BuildContext context, {
  required ProgressCelebrationKind kind,
  String? previousLevel,
  String? nextLevel,
  int inactiveDays = 3,
}) => showModalBottomSheet<bool>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: const Color(0xFF102F55),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (_) => ProgressCelebrationSheet(
    kind: kind,
    previousLevel: previousLevel,
    nextLevel: nextLevel,
    inactiveDays: inactiveDays,
  ),
);

class ProgressCelebrationSheet extends StatefulWidget {
  const ProgressCelebrationSheet({
    super.key,
    required this.kind,
    this.previousLevel,
    this.nextLevel,
    this.inactiveDays = 3,
  });
  final ProgressCelebrationKind kind;
  final String? previousLevel;
  final String? nextLevel;
  final int inactiveDays;

  @override
  State<ProgressCelebrationSheet> createState() =>
      _ProgressCelebrationSheetState();
}

class _ProgressCelebrationSheetState extends State<ProgressCelebrationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = 1;
    } else if (!_animation.isAnimating && _animation.value == 0) {
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.kind == ProgressCelebrationKind.levelUp;
    final accent = level ? const Color(0xFF73D8FF) : const Color(0xFFFFBE7D);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF194D7C), Color(0xFF102F55), Color(0xFF0B2442)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  level ? 'LEVELAUFSTIEG' : 'DEIN COMEBACK',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final reveal = Curves.easeOutBack.transform(
                      (_animation.value * 2).clamp(0, 1),
                    );
                    return SizedBox(
                      height: 172,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _CelebrationParticles(
                          progress: _animation.value,
                          color: accent,
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale: .7 + .3 * reveal,
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accent.withValues(alpha: .25),
                                    accent.withValues(alpha: .07),
                                  ],
                                ),
                                border: Border.all(
                                  color: accent.withValues(alpha: .6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: .14),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                level
                                    ? Icons.workspace_premium_rounded
                                    : Icons.wb_sunny_rounded,
                                size: 58,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  level
                      ? 'Du wächst über Dich hinaus.'
                      : 'Schön, dass Du\nwieder da bist.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 22),
                if (level)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: .2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.previousLevel ?? 'Beginner',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        Text(
                          widget.nextLevel ?? 'Athlet',
                          style: TextStyle(
                            color: accent,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Nach ${widget.inactiveDays} Tagen Pause\nbist Du wieder in Bewegung.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  level
                      ? 'Deine Konstanz zahlt sich aus.\nDas hast Du Dir erarbeitet.'
                      : 'Heute zählt. Und Du bist da.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF102F55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Text(
                    level ? 'STARK – WEITER SO!' : 'WEITER GEHT’S',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationParticles extends CustomPainter {
  const _CelebrationParticles({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 22; i++) {
      final angle = i * math.pi * 2 / 22;
      final radius = 60 + 52 * Curves.easeOut.transform(progress) + (i % 3) * 6;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final opacity = (1 - progress * .8) * (i.isEven ? .85 : .4);
      final paint = Paint()
        ..color = (i % 4 == 0 ? Colors.white : color).withValues(
          alpha: opacity,
        );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: i.isEven ? 4 : 2,
            height: i.isEven ? 9 : 3,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationParticles oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
