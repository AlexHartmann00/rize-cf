import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/muscle_visualizer.dart';

void main() {
  for (final groups in <List<String>>[
    ['Upper Back'],
    ['Upper Back', 'Rear Shoulders'],
    ['Rear Shoulders', 'Upper Back'],
  ]) {
    testWidgets('filled back is symmetric with muscles $groups', (
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
                impactScore: 0.5,
                baseReps: 10,
              ),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(MuscleVisualization));
      await tester.runAsync(() async {
        for (final asset in ['base_back', 'upper back', 'shoulders']) {
          await precacheImage(
            AssetImage('assets/muscle_graphics/back/$asset.png'),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey<String>('symmetric-back-body')),
      );
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 800 / 132),
      ))!;
      final data = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      int colored = 0;
      int mismatches = 0;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width ~/ 2; x++) {
          final left = (y * image.width + x) * 4;
          final right = (y * image.width + image.width - 1 - x) * 4;
          if (data.getUint8(left) > 150 &&
              data.getUint8(left + 1) < 160 &&
              data.getUint8(left + 3) > 128)
            colored++;
          for (int c = 0; c < 4; c++) {
            if ((data.getUint8(left + c) - data.getUint8(right + c)).abs() > 2)
              mismatches++;
          }
        }
      }
      expect(
        colored,
        greaterThan(1000),
        reason: 'Verify loaded muscle fills, not an empty image.',
      );
      expect(
        mismatches,
        0,
        reason: 'The rendered outline and fills must mirror each other.',
      );
      if (Platform.environment['RIZE_SYMMETRY_PREVIEW']
          case final String path) {
        final png = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        File(path).writeAsBytesSync(png!.buffer.asUint8List());
      }
      if (groups.length == 1) {
        // Interior rear-deltoid pixels must stay transparent when only the
        // upper back is listed. This catches overlap in the source artwork.
        final int x = (image.width * 115 / 129).floor();
        final int y = (image.height * 94 / 400).floor();
        final int pixel = (y * image.width + x) * 4;
        expect(data.getUint8(pixel + 3), 0);
      }
      image.dispose();
    });
  }
}
