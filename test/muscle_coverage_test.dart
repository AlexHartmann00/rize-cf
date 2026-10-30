import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/muscle_group_labels.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/muscle_visualizer.dart';

Workout example(List<String> groups) => Workout(
  id: 'audit',
  name: 'Muscle audit',
  description: '',
  coachingCues: '',
  usedMuscleGroups: groups,
  tags: [],
  workoutType: WorkoutType.dynamic,
  impactScore: .5,
);

Set<String> catalogueGroups() {
  final groups = <String>{};
  for (final file in [
    'firebase_service/workouts.json',
    'assets/data/workouts.json',
  ]) {
    final data =
        jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>;
    final workouts = (data['exercises'] ?? data['workout_types']) as List;
    for (final workout in workouts) {
      for (final group
          in (workout['muscleGroups'] ?? workout['usedMuscleGroups']) as List) {
        groups.add(group is String ? group : group['name'] as String);
      }
    }
  }
  return groups;
}

void main() {
  test(
    'every current, legacy and translated muscle name has existing masks',
    () {
      for (final group in {...catalogueGroups(), ...muscleGroupSearchTerms}) {
        final paths = [
          ...muscleAssetPaths(group, true),
          ...muscleAssetPaths(group, false),
        ];
        expect(
          paths,
          isNotEmpty,
          reason: 'Missing muscle visualization: $group',
        );
        for (final path in paths) {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: '$group maps to absent $path',
          );
        }
      }
    },
  );

  test(
    'only valid body sides resolve, and unknown groups do not invent paths',
    () {
      expect(muscleAssetPaths('Chest', false), isEmpty);
      expect(muscleAssetPaths('Triceps', true), isEmpty);
      expect(muscleAssetPaths('Rear Shoulders', true), isEmpty);
      expect(muscleAssetPaths('Front Shoulders', false), isEmpty);
      expect(muscleAssetPaths('Abs', false), isEmpty);
      expect(
        muscleAssetPaths('Abdominals', true),
        muscleAssetPaths('Abs', true),
      );
      expect(muscleAssetPaths('unknown', true), isEmpty);
      expect(MuscleVisualizer().getMuscleImage('unknown', false), isNull);
    },
  );

  testWidgets('upper back cannot split either rear shoulder into two colours', (
    tester,
  ) async {
    Future<ui.Image> render(List<String> groups) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleVisualization(workout: example(groups), large: true),
          ),
        ),
      );
      final context = tester.element(find.byType(MuscleVisualization));
      await tester.runAsync(() async {
        for (final path in [
          'assets/muscle_graphics/back/base_back.png',
          'assets/muscle_graphics/front/base_front.png',
          'assets/muscle_graphics/back/shoulders.png',
          'assets/muscle_graphics/back/upper back.png',
        ]) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey<String>('symmetric-back-body')),
      );
      return (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 800 / 132),
      ))!;
    }

    final shoulder = await render(['Rear Shoulders']);
    final primary = await render(['Rear Shoulders', 'Upper Back']);
    final secondary = await render(['Upper Back', 'Rear Shoulders']);
    final buffers = await tester.runAsync(
      () async => [
        for (final image in [shoulder, primary, secondary])
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
      ],
    );
    final data = buffers!;
    var shoulderPixels = 0;
    for (var pixel = 0; pixel < data.first.lengthInBytes; pixel += 4) {
      // Compare solid interiors; antialiased edges have separate symmetry tests.
      if (data[0].getUint8(pixel) < 220 ||
          data[0].getUint8(pixel) > 240 ||
          data[0].getUint8(pixel + 1) > 75 ||
          data[0].getUint8(pixel + 3) < 250) {
        continue;
      }
      shoulderPixels++;
      expect(
        data[1].getUint8(pixel + 1),
        lessThan(80),
        reason: 'Primary shoulder must stay red across its entire area.',
      );
      expect(data[2].getUint8(pixel), greaterThan(245));
      expect(
        data[2].getUint8(pixel + 1),
        greaterThan(120),
        reason: 'Secondary shoulder must stay orange across its entire area.',
      );
    }
    expect(shoulderPixels, greaterThan(1000));
    for (final image in [shoulder, primary, secondary]) {
      image.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('all muscle groups and shoulder combinations render together', (
    tester,
  ) async {
    final groups = <List<String>>[
      ['Chest'],
      ['Front Shoulders'],
      ['Rear Shoulders'],
      ['Upper Back'],
      ['Lower Back'],
      ['Triceps'],
      ['Biceps'],
      ['Abs'],
      ['Obliques'],
      ['Glutes'],
      ['Quadriceps'],
      ['Hamstrings'],
      ['Calves'],
      ['Upper Back', 'Rear Shoulders'],
      ['Rear Shoulders', 'Upper Back'],
      ['Glutes', 'Hamstrings', 'Lower Back'],
      ['Ganzkörper'],
      ['Rücken', 'Beine'],
    ];
    await tester.binding.setSurfaceSize(const Size(1170, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: RepaintBoundary(
            key: const ValueKey('audit-preview'),
            child: ColoredBox(
              color: const Color(0xFF15375F),
              child: Wrap(
                children: [
                  for (final item in groups)
                    SizedBox(
                      width: 390,
                      height: 180,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: MuscleVisualization(
                          workout: example(item),
                          large: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(Wrap).first);
    await tester.runAsync(() async {
      for (final file in Directory(
        'assets/muscle_graphics',
      ).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.png')) {
          await precacheImage(AssetImage(file.path), context);
        }
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.environment['RIZE_MUSCLE_AUDIT_PREVIEW']
        case final String path) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('audit-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
