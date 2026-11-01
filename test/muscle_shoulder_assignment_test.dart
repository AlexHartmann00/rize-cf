import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/widgets/muscle_visualizer.dart';

void main() {
  for (final groups in [
    ['Upper Back'],
    ['Rear Shoulders'],
    ['Upper Back', 'Rear Shoulders'],
    ['Rear Shoulders', 'Upper Back'],
  ]) {
    testWidgets(
      'inner neck belongs to back, outer shoulder to deltoid: $groups',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MuscleVisualization(
                large: true,
                workout: Workout(
                  id: 'shoulders',
                  name: '',
                  description: '',
                  coachingCues: '',
                  usedMuscleGroups: groups,
                  tags: [],
                  workoutType: WorkoutType.dynamic,
                  impactScore: .5,
                ),
              ),
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
        final image = (await tester.runAsync(
          () => boundary.toImage(pixelRatio: 800 / 132),
        ))!;
        final data = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        void expectRegion(int sourceX, int sourceY, String group) {
          for (final xSource in [sourceX, 129 - sourceX]) {
            final x = (image.width * xSource / 129).floor();
            final y = (image.height * sourceY / 400).floor();
            final pixel = (y * image.width + x) * 4;
            final index = groups.indexOf(group);
            if (index < 0) {
              expect(
                data.getUint8(pixel + 3),
                lessThan(20),
                reason:
                    '$group must stay empty when not trained at $xSource,$sourceY',
              );
            } else {
              final color = index == 0
                  ? const Color(0xFFE93B3B)
                  : const Color(0xFFFF8A3D);
              expect(data.getUint8(pixel), closeTo((color.r * 255).round(), 3));
              expect(
                data.getUint8(pixel + 1),
                closeTo((color.g * 255).round(), 3),
              );
              expect(data.getUint8(pixel + 3), greaterThan(245));
            }
          }
        }

        // Both previously empty compartments between neck and outer shoulder.
        expectRegion(80, 66, 'Upper Back');
        expectRegion(80, 75, 'Upper Back');
        expectRegion(98, 72, 'Upper Back');
        expectRegion(112, 85, 'Rear Shoulders');
        expectRegion(118, 96, 'Rear Shoulders');
        expect(tester.takeException(), isNull);
        final path = Platform.environment['RIZE_SHOULDER_PREVIEW'];
        if (groups.first == 'Upper Back' &&
            groups.length == 2 &&
            path != null) {
          await tester.runAsync(() async {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
        image.dispose();
      },
    );
  }
}
