import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/home_page_widgets.dart';

ScheduledWorkout completed(String name) => ScheduledWorkout(
  id: name,
  name: name,
  description: '',
  coachingCues: '',
  usedMuscleGroups: [],
  tags: [],
  workoutType: WorkoutType.dynamic,
  baseReps: 10,
  impactScore: .7,
  intensityFactor: 1,
  schedule: [
    WorkoutStep(timeOfDay: TimeOfDay.any, plannedUnits: 1, completedUnits: 1),
  ],
);

void main() {
  for (final streak in [0, 1, 3]) {
    testWidgets(
      'series and countdown show values, never widget instances: $streak',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompletedWorkoutHero(
                  workouts: [completed('Scapular Retraction Bent Over')],
                  streak: streak,
                  nextWorkoutIn: '14 Std. 42 Min.',
                  progress: 1,
                ),
              ),
            ),
          ),
        );
        expect(
          find.text('$streak ${streak == 1 ? 'Tag' : 'Tage'}'),
          findsOneWidget,
        );
        expect(find.text('In 14 Std. 42 Min. bereit.'), findsOneWidget);
        final text = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data ?? '')
            .join(' ');
        expect(text, isNot(contains('Instance of')));
        expect(text, isNot(contains('CompletedWorkoutHero')));
        expect(text, isNot(contains('widget.')));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 1.6, 2.0]) {
    testWidgets('completion card fits narrow screens with text scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CompletedWorkoutHero(
                    workouts: [
                      completed('Scapular Retraction Bent Over'),
                      completed('Knee Push-Up Shouldertap'),
                    ],
                    streak: 123,
                    nextWorkoutIn: '14 Std. 42 Min.',
                    progress: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('1.40'), findsOneWidget);
      expect(find.text('123 Tage'), findsOneWidget);
      expect(
        find.textContaining('Scapular Retraction Bent Over'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'greeting has no subtitle and a partial impulse has one completion headline',
    (tester) async {
      final workout = completed('V-Up');
      workout.schedule.single.actualValue = 5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const CoachFloHomeHeader(
                    greeting: 'Guten Morgen, Flo',
                    streak: 0,
                  ),
                  CompletedWorkoutHero(
                    workouts: [workout],
                    streak: 0,
                    nextWorkoutIn: '13 Std. 12 Min.',
                    progress: .5,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final header = find.byType(CoachFloHomeHeader);
      final headerTexts = tester
          .widgetList<Text>(
            find.descendant(of: header, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .toList();
      expect(headerTexts, ['Guten Morgen, Flo', '0']);
      expect(find.text('Impuls erledigt'), findsOneWidget);
      expect(find.text('TAGESAUFGABE'), findsOneWidget);
      expect(find.text('50 % des Tagesziels geschafft'), findsOneWidget);
      for (final old in [
        'Training beendet',
        'Training beendet!',
        'Workout geschafft',
        'Abgeschlossen',
      ]) {
        expect(find.text(old), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('render completed home preview', (tester) async {
    final path = Platform.environment['RIZE_COMPLETED_PREVIEW'];
    if (path == null) return;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 28);
    addTearDown(() {
      tester.view.resetPadding();
      tester.binding.setSurfaceSize(null);
    });
    await ui.loadFontFromList(
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync(),
      fontFamily: 'PreviewFont',
    );
    await ui.loadFontFromList(
      (await rootBundle.load(
        'fonts/MaterialIcons-Regular.otf',
      )).buffer.asUint8List(),
      fontFamily: 'MaterialIcons',
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('completed-preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'PreviewFont'),
          home: RizeScaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1879CB),
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart_rounded),
                  label: 'Fortschritt',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmarks_rounded),
                  label: 'Bibliothek',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CoachFloHomeHeader(
                        greeting: 'Guten Morgen, Alex',
                        streak: 1,
                      ),
                      const SizedBox(height: 22),
                      CompletedWorkoutHero(
                        workouts: [completed('Scapular Retraction Bent Over')],
                        streak: 1,
                        nextWorkoutIn: '14 Std. 42 Min.',
                        progress: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(RizeScaffold));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/rize_logo_r.png'),
        context,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('completed-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
