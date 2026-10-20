import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/questionnaire_launch_guard.dart';

void main() {
  testWidgets('resume cannot stack questionnaires during loading or answering', (
    WidgetTester tester,
  ) async {
    final guard = QuestionnaireLaunchGuard();
    final loaded = Completer<void>();
    final navigatorKey = GlobalKey<NavigatorState>();
    bool submitted = false;
    int loads = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Home')),
      ),
    );

    Future<void> checkOnboarding() => guard.run(() async {
      if (submitted) return;
      loads++;
      await loaded.future;
      await navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: TextButton(
              onPressed: () {
                submitted = true;
                navigatorKey.currentState!.pop();
              },
              child: const Text('Finish questionnaire'),
            ),
          ),
        ),
      );
    });

    final firstLaunch = checkOnboarding();
    // A resume while the questions are still loading must not start a new load.
    await checkOnboarding();
    expect(loads, 1);
    loaded.complete();
    await tester.pumpAndSettle();

    // A resume while answering must not push another copy of the route.
    await checkOnboarding();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish questionnaire'));
    await tester.pumpAndSettle();
    await firstLaunch;

    expect(find.text('Home'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    await checkOnboarding();
    expect(loads, 1);
  });

  test('failed loading releases the guard for a later retry', () async {
    final guard = QuestionnaireLaunchGuard();
    await expectLater(
      guard.run(() async => throw StateError('Loading failed')),
      throwsStateError,
    );

    bool retried = false;
    await guard.run(() async => retried = true);
    expect(retried, isTrue);
  });
}
