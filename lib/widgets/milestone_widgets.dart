import 'package:flutter/material.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/helpers/rize_style_helpers.dart';
import 'package:rize/types/workout.dart';

Future<void> showMilestoneCelebration(
  BuildContext context,
  List<MilestoneState> milestones,
) async {
  if (milestones.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _MilestoneCelebrationSheet(milestones: milestones),
  );
}

class _MilestoneCelebrationSheet extends StatefulWidget {
  const _MilestoneCelebrationSheet({required this.milestones});

  final List<MilestoneState> milestones;

  @override
  State<_MilestoneCelebrationSheet> createState() =>
      _MilestoneCelebrationSheetState();
}

class _MilestoneCelebrationSheetState
    extends State<_MilestoneCelebrationSheet> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final MilestoneState milestone = widget.milestones[_index];
    final bool last = _index == widget.milestones.length - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: const BoxDecoration(
          color: Color(0xFF102F55),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'MEILENSTEIN ERREICHT',
              style: TextStyle(
                color: rizeCyan,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 94,
              height: 94,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    rizeCyan.withOpacity(0.28),
                    rizeBlue.withOpacity(0.18),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: rizeCyan.withOpacity(0.35)),
              ),
              child: Text(
                milestone.definition.emoji,
                style: const TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              milestone.definition.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              milestone.definition.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (widget.milestones.length > 1) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                '${_index + 1} von ${widget.milestones.length} neuen Meilensteinen',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                if (last) {
                  Navigator.pop(context);
                } else {
                  setState(() => _index++);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10539E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                last ? 'STARK – WEITER SO!' : 'NÄCHSTER MEILENSTEIN',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MilestoneOverviewCard extends StatefulWidget {
  const MilestoneOverviewCard({super.key, required this.history});

  final List<ScheduledWorkout> history;

  @override
  State<MilestoneOverviewCard> createState() => _MilestoneOverviewCardState();
}

class _MilestoneOverviewCardState extends State<MilestoneOverviewCard> {
  MilestoneCategory _category = MilestoneCategory.career;

  @override
  Widget build(BuildContext context) {
    final List<MilestoneState> states = buildMilestoneStates(
      widget.history,
    ).where((state) => state.definition.category == _category).toList();
    states.sort((a, b) {
      if (a.reached != b.reached) return a.reached ? -1 : 1;
      return b.progress.compareTo(a.progress);
    });
    final List<MilestoneState> preview = states.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.075),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.emoji_events_rounded, color: rizeOrange),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Deine Meilensteine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<MilestoneCategory>(
            segments: const <ButtonSegment<MilestoneCategory>>[
              ButtonSegment(
                value: MilestoneCategory.career,
                label: Text('Gesamt'),
              ),
              ButtonSegment(
                value: MilestoneCategory.weekly,
                label: Text('Woche'),
              ),
              ButtonSegment(
                value: MilestoneCategory.monthly,
                label: Text('Monat'),
              ),
            ],
            selected: <MilestoneCategory>{_category},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _category = value.first),
          ),
          const SizedBox(height: 14),
          ...preview.map((state) => _MilestoneProgressRow(state: state)),
          TextButton(
            onPressed: () => _showAll(context, states),
            child: const Text('ALLE MEILENSTEINE ANSEHEN'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAll(BuildContext context, List<MilestoneState> states) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF102F55),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          maxChildSize: 0.94,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(
                'Deine Meilensteine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...states.map((state) => _MilestoneProgressRow(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneProgressRow extends StatelessWidget {
  const _MilestoneProgressRow({required this.state});
  final MilestoneState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: state.reached
              ? rizeGreen.withOpacity(0.12)
              : Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Text(state.definition.emoji, style: const TextStyle(fontSize: 25)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.definition.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      color: state.reached ? rizeGreen : rizeCyan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              state.reached ? '✓' : state.progressLabel,
              style: TextStyle(
                color: state.reached ? rizeGreen : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
