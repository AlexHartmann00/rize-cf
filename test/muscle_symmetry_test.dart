import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/muscle_visualizer.dart';

void main() {
  for (final groups in <List<String>>[
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
    ['Rear Shoulders', 'Shoulder'],
    ['Glutes', 'Hamstrings', 'Lower Back'],
  ]) {
    for (final front in [true, false]) {
      if (!groups.any((group) => muscleAssetPaths(group, front).isNotEmpty)) {
        continue;
      }
      final side = front ? 'front' : 'back';
      testWidgets('$side outline and muscle fills are symmetric: $groups', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MuscleVisualization(
                large: true,
                workout: Workout(
                  id: 'symmetry',
                  name: 'Test',
                  description: '',
                  coachingCues: '',
                  usedMuscleGroups: groups,
                  tags: [],
                  workoutType: WorkoutType.dynamic,
                  impactScore: .5,
                  baseReps: 10,
                ),
              ),
            ),
          ),
        );
        final context = tester.element(find.byType(MuscleVisualization));
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
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(ValueKey<String>('symmetric-$side-body')),
        );
        final image = (await tester.runAsync(
          () => boundary.toImage(pixelRatio: 800 / 132),
        ))!;
        final data = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        int colored = 0;
        int mismatches = 0;
        int secondary = 0;
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width ~/ 2; x++) {
            final left = (y * image.width + x) * 4;
            final right = (y * image.width + image.width - 1 - x) * 4;
            if (data.getUint8(left) > 150 &&
                data.getUint8(left + 1) < 160 &&
                data.getUint8(left + 3) > 128) {
              colored++;
            }
            if (data.getUint8(left) > 240 &&
                data.getUint8(left + 1) > 100 &&
                data.getUint8(left + 1) < 170 &&
                data.getUint8(left + 3) > 128) {
              secondary++;
            }
            for (int c = 0; c < 4; c++) {
              // Allow small antialiasing/rounding differences at fractional
              // layer edges (8/255), while rejecting asymmetric shapes/fills.
              if ((data.getUint8(left + c) - data.getUint8(right + c)).abs() >
                  8) {
                mismatches++;
              }
            }
          }
        }
        expect(
          colored,
          greaterThan(600),
          reason: 'Verify real muscle highlights, not just an empty outline.',
        );
        expect(
          mismatches,
          0,
          reason:
              'Both shoulders, outlines and muscle fills must mirror each other.',
        );
        if (!front &&
            groups.length == 2 &&
            groups.first == 'Rear Shoulders' &&
            groups.last == 'Shoulder') {
          expect(
            secondary,
            0,
            reason:
                'A duplicate alias must not overwrite the primary muscle colour.',
          );
        }
        bool highlighted(int sourceX, int sourceY) {
          final sourceWidth = front ? 127 : 129;
          final x = (image.width * sourceX / sourceWidth).floor();
          final y = (image.height * sourceY / 400).floor();
          final pixel = (y * image.width + x) * 4;
          return data.getUint8(pixel) > 150 &&
              data.getUint8(pixel + 1) < 160 &&
              data.getUint8(pixel + 3) > 128;
        }

        if (!front && groups.length == 1) {
          switch (groups.single) {
            case 'Upper Back':
              expect(
                highlighted(115, 94),
                isFalse,
                reason: 'Upper back must not fill the rear deltoid.',
              );
            case 'Triceps':
              expect(
                highlighted(115, 160),
                isFalse,
                reason: 'Upper arm must not fill the forearm.',
              );
            case 'Glutes':
              expect(
                highlighted(92, 240),
                isFalse,
                reason: 'Glutes must not fill the outer thigh.',
              );
          }
        }
        image.dispose();
      });
    }
  }
}
