import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/widgets/progress_celebration.dart';
import 'package:rize/widgets/milestone_widgets.dart';
import 'package:rize/helpers/milestone_service.dart';

void main() {
  for (final kind in ProgressCelebrationKind.values) {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(700, 400),
    ]) {
      testWidgets('$kind fits $size and acknowledges only on confirmation', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        tester.view.padding = const FakeViewPadding(bottom: 34);
        addTearDown(() {
          tester.view.resetPadding();
          tester.binding.setSurfaceSize(null);
        });
        final preview = Platform.environment['RIZE_CELEBRATION_PREVIEWS'];
        if (preview != null) {
          await ui.loadFontFromList(
            File(
              '/System/Library/Fonts/Supplemental/Arial.ttf',
            ).readAsBytesSync(),
            fontFamily: 'PreviewFont',
          );
          await ui.loadFontFromList(
            (await rootBundle.load(
              'fonts/MaterialIcons-Regular.otf',
            )).buffer.asUint8List(),
            fontFamily: 'MaterialIcons',
          );
        }
        bool? acknowledged;
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('preview-screen'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: preview != null ? 'PreviewFont' : null,
              ),
              home: Scaffold(
                backgroundColor: const Color(0xFF0B2442),
                body: Builder(
                  builder: (context) => Center(
                    child: TextButton(
                      child: const Text('Öffnen'),
                      onPressed: () async {
                        acknowledged = await presentProgressCelebration(
                          context,
                          kind: kind,
                          previousLevel: 'Beginner',
                          nextLevel: 'Athlet',
                          inactiveDays: 3,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Öffnen'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(ProgressCelebrationSheet), findsOneWidget);
        expect(acknowledged, isNull);
        if (preview != null && size.width == 390) {
          for (var frame = 0; frame < 16; frame++) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('preview-screen')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '$preview/${kind.name}_frame${frame.toString().padLeft(2, '0')}.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
              image.dispose();
            });
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (kind == ProgressCelebrationKind.levelUp) {
          expect(find.text('Athlet'), findsOneWidget);
          expect(find.text('Beginner'), findsOneWidget);
        } else {
          expect(find.text('Heute zählt. Und Du bist da.'), findsOneWidget);
        }
        if (preview != null && size.width == 390) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview-screen')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '$preview/${kind.name}.png',
            ).writeAsBytesSync(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        final button = find.byType(FilledButton);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(acknowledged, isTrue);
        expect(find.byType(ProgressCelebrationSheet), findsNothing);
      });
    }
  }

  testWidgets('milestone background covers bottom safe area', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('screen'),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Show'),
                onPressed: () => showMilestoneCelebration(context, [
                  MilestoneState(
                    definition: milestoneDefinitions.first,
                    current: 1,
                    storageId: 'test',
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('screen')),
    );
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final pixel = ((image.height - 2) * image.width + image.width ~/ 2) * 4;
    expect(bytes.getUint8(pixel), 0x10);
    expect(bytes.getUint8(pixel + 1), 0x2F);
    expect(bytes.getUint8(pixel + 2), 0x55);
    image.dispose();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  });
}
