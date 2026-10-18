import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/milestone_service.dart';
import 'package:rize/widgets/milestone_widgets.dart';

void main() {
  final milestone = MilestoneState(
    definition: milestoneDefinitions.first,
    current: 1,
    storageId: 'first_workout',
  );

  testWidgets('completion during an earlier check is queued and shown once', (
    tester,
  ) async {
    final coordinator = MilestoneCelebrationCoordinator();
    final initialCheck = Completer<List<MilestoneState>>();
    late BuildContext context;
    var acknowledged = false;
    String? acknowledgedId;
    var checks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    Future<void> markShown(Iterable<MilestoneState> states) async {
      acknowledgedId = states.single.storageId;
      acknowledged = true;
    }

    final first = coordinator.celebrate(
      context,
      load: () => initialCheck.future,
      markShown: markShown,
    );
    await tester.pump();
    Future<List<MilestoneState>> loadCompleted() async {
      checks++;
      return acknowledged ? [] : [milestone];
    }

    final second = coordinator.celebrate(
      context,
      load: loadCompleted,
      markShown: markShown,
    );
    final third = coordinator.celebrate(
      context,
      load: loadCompleted,
      markShown: markShown,
    );
    initialCheck.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('MEILENSTEIN ERREICHT'), findsOneWidget);
    expect(checks, 1);
    expect(acknowledged, isFalse);
    await tester.tap(find.text('STARK – WEITER SO!'));
    await tester.pumpAndSettle();
    await Future.wait([first, second, third]);
    expect(checks, 2);
    expect(acknowledged, isTrue);
    expect(acknowledgedId, 'first_workout');
    expect(find.text('MEILENSTEIN ERREICHT'), findsNothing);
  });

  testWidgets('a failed check does not block a later celebration', (
    tester,
  ) async {
    final coordinator = MilestoneCelebrationCoordinator();
    late BuildContext context;
    var marked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    Future<void> markShown(Iterable<MilestoneState> states) async {
      marked = true;
    }

    final failed = coordinator.celebrate(
      context,
      load: () async => throw StateError('Temporary read failure'),
      markShown: markShown,
    );
    final retry = coordinator.celebrate(
      context,
      load: () async => [milestone],
      markShown: markShown,
    );
    await tester.pumpAndSettle();
    expect(find.text('MEILENSTEIN ERREICHT'), findsOneWidget);
    expect(marked, isFalse);
    await tester.tap(find.text('STARK – WEITER SO!'));
    await tester.pumpAndSettle();
    await Future.wait([failed, retry]);
    expect(marked, isTrue);
  });
}
