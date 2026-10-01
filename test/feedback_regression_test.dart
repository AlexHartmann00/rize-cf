import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/home_page_helpers.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/pages/progress_overview_content.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/milestone_widgets.dart';
import 'package:rize/widgets/muscle_visualizer.dart';
import 'package:rize/widgets/progress_overview_widgets.dart';

void main() {
  test('nighttime motivation reflects the available daily impulse', () {
    for (final hour in [0, 3, 5]) {
      expect(
        dailyMotivation(DateTime(2026, 10, 1, hour)),
        'Dein neuer Impuls ist freigeschaltet. Jetzt oder nach dem Aufstehen – er läuft dir nicht weg.',
      );
    }
    expect(dailyMotivation(DateTime(2026, 10, 1, 6)), contains('Starte'));
  });

  testWidgets('all muscle labels fit on a narrow technique card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MuscleVisualization(
        large: true,
        workout: Workout(
          id: 'swimmer', name: 'Prone Swimmer', description: '', coachingCues: '',
          usedMuscleGroups: ['Upper Back', 'Rear Shoulders', 'Lower Back', 'Glutes'],
          tags: [], workoutType: WorkoutType.static, impactScore: .6,
          baseSeconds: 8,
        ),
      )),
    ));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.textContaining(' · '),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar crosses year boundaries and returns to current month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WorkoutHistoryCalendar(
        today: DateTime(2026, 1, 10),
        history: const [], scoreDeltas: const {},
      )),
    ));
    expect(tester.widget<ActivityCalendarCard>(find.byType(ActivityCalendarCard)).month,
        DateTime(2026, 1));
    expect(tester.widget<IconButton>(find.byTooltip('Nächster Monat')).onPressed, isNull);
    await tester.tap(find.byTooltip('Vorheriger Monat'));
    await tester.pump();
    expect(tester.widget<ActivityCalendarCard>(find.byType(ActivityCalendarCard)).month,
        DateTime(2025, 12));
    await tester.tap(find.byTooltip('Nächster Monat'));
    await tester.pump();
    expect(tester.widget<ActivityCalendarCard>(find.byType(ActivityCalendarCard)).month,
        DateTime(2026, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('score chart dates have space at the right edge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final points = List.generate(30, (i) => ProgressPoint(
      index: i, date: DateTime(2026, 9, i + 1), value: .5,
    ));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProgressChartCard(
      impactPoints: points, scorePoints: points, currentScore: .5, lastImpact: null,
    ))));
    await tester.pumpAndSettle();
    final dates = ['1.9.', '10.9.', '19.9.', '28.9.'];
    for (var i = 1; i < dates.length; i++) {
      expect(tester.getRect(find.text(dates[i - 1])).right,
          lessThan(tester.getRect(find.text(dates[i])).left));
    }
    expect(find.text('30.9.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final confirm in [true, false]) {
    testWidgets('milestone reports acknowledgement only on confirmation: $confirm', (tester) async {
      bool? acknowledged;
      final milestone = MilestoneState(
        definition: milestoneDefinitions.first, current: 100, storageId: 'test',
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
        builder: (context) => TextButton(
          child: const Text('Öffnen'),
          onPressed: () async {
            acknowledged = await showMilestoneCelebration(context, [milestone]);
          },
        ),
      ))));
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      expect(find.text('MEILENSTEIN ERREICHT'), findsOneWidget);
      if (confirm) {
        await tester.tap(find.byType(FilledButton));
      } else {
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
      }
      await tester.pumpAndSettle();
      expect(acknowledged, confirm);
    });
  }
}
