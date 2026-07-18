import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/helpers/home_page_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/workout_rounds_list.dart';
import 'package:rize/pages/settings_page.dart';
import 'package:rize/types/anamnesis.dart';
import 'package:rize/widgets/anamnesis_questionnaire_flow.dart';
import 'package:rize/widgets/pro_upgrade_cta.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/widgets/milestone_widgets.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/widgets/drag_safe_filter_chip.dart';

Workout workout(
  String id,
  List<String> muscles, {
  List<String> tags = const <String>[],
}) => Workout(
  id: id,
  name: id,
  description: '',
  coachingCues: '',
  usedMuscleGroups: muscles,
  tags: tags,
  workoutType: WorkoutType.dynamic,
  impactScore: 0.5,
  baseReps: 10,
);

void main() {
  testWidgets('swiping from a filter chip does not select it', (
    WidgetTester tester,
  ) async {
    final Set<String> selected = <String>{};
    const List<String> tags = <String>[
      'Impact',
      'Knee',
      'LowerBack',
      'Shoulder',
      'Wrist',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 150),
                SizedBox(
                  width: 400,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (String tag) => DragSafeFilterChip(
                            key: ValueKey<String>(tag),
                            label: Text(tag),
                            selected: selected.contains(tag),
                            onSelected: (bool value) => value
                                ? selected.add(tag)
                                : selected.remove(tag),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 800),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('Impact')),
      const Offset(0, -40),
    );
    await tester.pump();

    expect(selected, isEmpty);

    final Offset wristBottomRight = tester.getBottomRight(
      find.byKey(const ValueKey<String>('Wrist')),
    );
    await tester.dragFrom(
      wristBottomRight + const Offset(30, -10),
      const Offset(0, -40),
    );
    await tester.pump();

    expect(selected, isEmpty);

    await tester.tap(find.byKey(const ValueKey<String>('Wrist')));
    await tester.pump();

    expect(selected, <String>{'Wrist'});
  });

  testWidgets('RIZE background fills the viewport with short content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RizeScaffold(body: SizedBox(height: 100))),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey<String>('rize-background'))),
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
  });

  test('exclusion tags have German labels', () {
    expect(muscleGroupLabel('Impact'), 'Stoßbelastung');
    expect(muscleGroupLabel('Knee'), 'Knie');
    expect(muscleGroupLabel('LowerBack'), 'Unterer Rücken');
    expect(muscleGroupLabel('Shoulder'), 'Schulter');
    expect(muscleGroupLabel('Wrist'), 'Handgelenk');
    expect(muscleGroupLabel('Front Shoulders'), 'Vordere Schultern');
    expect(muscleGroupLabel('Rear Shoulders'), 'Hintere Schultern');
  });

  test('YouTube IDs are extracted from current sharing URL formats', () {
    expect(
      youtubeVideoIdFromUrl('https://youtu.be/5BNYPq1WRek?si=uUvfJDTpBjhSgVhT'),
      '5BNYPq1WRek',
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/watch?v=5BNYPq1WRek'),
      '5BNYPq1WRek',
    );
    expect(
      youtubeVideoIdFromUrl('https://www.youtube.com/embed/5BNYPq1WRek'),
      '5BNYPq1WRek',
    );
    expect(youtubeVideoIdFromUrl('https://example.com/5BNYPq1WRek'), isEmpty);
  });

  test('library search matches German muscle names', () {
    final Workout shoulderWorkout = workout('rotation', const <String>[
      'Rear Shoulders',
    ]);
    expect(workoutMatchesSearch(shoulderWorkout, 'hintere Schulter'), isTrue);
    expect(workoutMatchesSearch(shoulderWorkout, 'vordere Schulter'), isFalse);
  });

  test('free Pro nudge appears once after five completed workouts', () {
    expect(
      shouldShowFreeProNudge(
        isPro: false,
        completedWorkoutCount: 4,
        wasAlreadyShown: false,
      ),
      isFalse,
    );
    expect(
      shouldShowFreeProNudge(
        isPro: false,
        completedWorkoutCount: 5,
        wasAlreadyShown: false,
      ),
      isTrue,
    );
    expect(
      shouldShowFreeProNudge(
        isPro: false,
        completedWorkoutCount: 6,
        wasAlreadyShown: true,
      ),
      isFalse,
    );
  });

  test('daily plan aggregates multiple independently completed workouts', () {
    final first = ScheduledWorkout.fromBaseWorkout(
      workout('a', const <String>['chest']),
      <WorkoutStep>[
        WorkoutStep(
          timeOfDay: TimeOfDay.any,
          plannedUnits: 2,
          completedUnits: 2,
        ),
      ],
      1,
    );
    final second = ScheduledWorkout.fromBaseWorkout(
      workout('b', const <String>['legs']),
      <WorkoutStep>[
        WorkoutStep(
          timeOfDay: TimeOfDay.any,
          plannedUnits: 2,
          completedUnits: 1,
        ),
      ],
      1,
    );
    final plan = DailyWorkoutPlan(
      id: 'plan',
      workouts: <ScheduledWorkout>[first, second],
    );
    expect(plan.progress, 0.75);
    expect(plan.isCompleted, isFalse);
  });

  test('free selection covers muscle groups with few workouts', () {
    final selection = freeWorkoutSelection(
      <Workout>[
        workout('combined', const <String>['chest', 'legs']),
        workout('chest', const <String>['chest']),
        workout('legs', const <String>['legs']),
      ],
      0.5,
      minimumWorkoutCount: 1,
    );
    expect(selection.map((Workout item) => item.id), <String>['combined']);
  });

  test('Pro entitlement returns the full workout catalogue', () {
    final catalogue = <Workout>[
      workout('one', const <String>['chest']),
      workout('two', const <String>['legs']),
    ];
    expect(
      availableWorkoutsForUser(
        workouts: catalogue,
        intensityScore: 0.5,
        isPro: true,
      ),
      catalogue,
    );
  });

  test('multi exercise spin prefers new muscle groups', () {
    final chest = workout('chest', const <String>['chest']);
    final chestAgain = workout('chest-2', const <String>['chest']);
    final legs = workout('legs', const <String>['quadriceps']);

    final selection = selectDiverseWorkouts(
      workouts: <Workout>[chest, chestAgain, legs],
      count: 2,
    );

    expect(selection.map((Workout item) => item.id), <String>['chest', 'legs']);
  });

  test('muscle filter is respected by diverse spin selection', () {
    final selection = selectDiverseWorkouts(
      workouts: <Workout>[
        workout('chest', const <String>['chest']),
        workout('legs', const <String>['quadriceps']),
      ],
      count: 2,
      muscleFilter: const <String>{'chest'},
    );

    expect(selection.map((Workout item) => item.id), <String>['chest']);
  });

  test('muscle exclusion uses workout tags instead of muscle groups', () {
    final List<Workout> selection = selectDiverseWorkouts(
      workouts: <Workout>[
        workout('tagged', <String>['chest'], tags: <String>['shoulders']),
        workout('muscle-only', <String>['shoulders']),
        workout('allowed', <String>['back']),
      ],
      count: 3,
      excludedTags: const <String>{'SHOULDERS'},
    );

    expect(selection.map((Workout item) => item.id), <String>[
      'muscle-only',
      'allowed',
    ]);
  });

  test('multiple selected muscle groups are rotated first', () {
    final selection = selectDiverseWorkouts(
      workouts: <Workout>[
        workout('chest-one', const <String>['chest', 'shoulders']),
        workout('chest-two', const <String>['chest', 'biceps']),
        workout('legs', const <String>['quadriceps']),
      ],
      count: 2,
      muscleFilter: const <String>{'chest', 'quadriceps'},
    );

    expect(selection.map((Workout item) => item.id), <String>[
      'chest-one',
      'legs',
    ]);
  });

  test('career, weekly and monthly milestones use workout history', () {
    final ScheduledWorkout completed = ScheduledWorkout.fromBaseWorkout(
      workout('milestone', const <String>['chest', 'quadriceps']),
      <WorkoutStep>[
        WorkoutStep(
          timeOfDay: TimeOfDay.any,
          plannedUnits: 1,
          completedUnits: 1,
          actualValue: 100,
        ),
      ],
      1,
    )..scheduledDay = DateTime.now();

    final states = buildMilestoneStates(<ScheduledWorkout>[completed]);

    expect(
      states
          .firstWhere((state) => state.definition.id == 'first_workout')
          .reached,
      isTrue,
    );
    expect(
      states.firstWhere((state) => state.definition.id == 'reps_100').reached,
      isTrue,
    );
    expect(
      states
          .firstWhere((state) => state.definition.id == 'week_days_3')
          .current,
      1,
    );
  });

  testWidgets('round list stays within a narrow phone layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scheduled = ScheduledWorkout.fromBaseWorkout(
      workout('Kneeling Lean Back', const <String>['quadriceps']),
      List<WorkoutStep>.generate(
        3,
        (_) => WorkoutStep(
          timeOfDay: TimeOfDay.any,
          plannedUnits: 1,
          completedUnits: 0,
        ),
      ),
      3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D376D),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: WorkoutRoundsList(workout: scheduled),
          ),
        ),
      ),
    );

    expect(find.text('DEINE RUNDEN'), findsOneWidget);
    expect(find.text('START'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings page uses an in-page header without an app bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Tagesaufgaben-Erinnerung'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('anamnesis presents one focused question at a time', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final questionnaire = AnamnesisQuestionnaire(
      entries: <QuestionnaireEntry>[
        QuestionnaireEntry(
          questionTitle: 'Alltag',
          questionText: 'Wie aktiv bist Du?',
          responseOptions: <QuestionnaireResponseOption>[
            QuestionnaireResponseOption(
              optionText: 'Eher ruhig',
              optionValue: 0.2,
            ),
            QuestionnaireResponseOption(
              optionText: 'Sehr aktiv',
              optionValue: 0.8,
            ),
          ],
        ),
        QuestionnaireEntry(
          questionTitle: 'Kraft',
          questionText: 'Wie fühlst Du Dich?',
          responseOptions: <QuestionnaireResponseOption>[
            QuestionnaireResponseOption(
              optionText: 'Einsteiger',
              optionValue: 0.2,
            ),
            QuestionnaireResponseOption(
              optionText: 'Trainiert',
              optionValue: 0.8,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnamnesisQuestionnaireFlow(questionnaire: questionnaire),
      ),
    );
    expect(find.text('Wie aktiv bist Du?'), findsOneWidget);
    expect(find.text('Wie fühlst Du Dich?'), findsNothing);
    await tester.tap(find.text('Sehr aktiv'));
    await tester.pump();
    await tester.tap(find.text('WEITER'));
    await tester.pumpAndSettle();
    expect(find.text('Wie fühlst Du Dich?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pro banner is a tappable upgrade entry point', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProUpgradeBanner(availableCount: 6, onTap: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.text('Mehr Abwechslung mit RIZE Pro'));
    expect(tapped, isTrue);
  });

  testWidgets('milestone overview fits a mobile viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0D376D),
          body: SingleChildScrollView(
            child: MilestoneOverviewCard(history: <ScheduledWorkout>[]),
          ),
        ),
      ),
    );

    expect(find.text('Deine Meilensteine'), findsOneWidget);
    expect(find.text('Gesamt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
