import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/helpers/workout_countdown_sound.dart';

void main() {
  test('plays only during the last three seconds and stops at zero', () async {
    final events = <String>[];
    final sound = WorkoutCountdownSound(
      play: (position) async {
        events.add('play:${position.inSeconds}');
      },
      stop: () async {
        events.add('stop');
      },
    );
    for (final remaining in [10, 9, 8, 7, 6, 5, 4]) {
      await sound.update(remainingSeconds: remaining, active: true);
    }
    expect(events, isEmpty);
    await sound.update(remainingSeconds: 3, active: true);
    expect(events, ['play:0']);
    await sound.update(remainingSeconds: 2, active: true);
    await sound.update(remainingSeconds: 1, active: true);
    expect(events, ['play:0']);
    await sound.update(remainingSeconds: 0, active: true);
    expect(events, ['play:0', 'stop']);
    await sound.update(remainingSeconds: 0, active: false);
    expect(events, ['play:0', 'stop']);
  });

  test(
    'pause stops playback and resume aligns to the remaining time',
    () async {
      final events = <String>[];
      final sound = WorkoutCountdownSound(
        play: (position) async {
          events.add('play:${position.inSeconds}');
        },
        stop: () async {
          events.add('stop');
        },
      );
      await sound.update(remainingSeconds: 3, active: true);
      await sound.update(remainingSeconds: 2, active: true);
      await sound.update(remainingSeconds: 2, active: false);
      expect(events, ['play:0', 'stop']);
      await sound.update(remainingSeconds: 2, active: true);
      expect(events, ['play:0', 'stop', 'play:1']);
      await sound.update(remainingSeconds: 1, active: true);
      await sound.update(remainingSeconds: 0, active: true);
      expect(events.last, 'stop');
    },
  );

  test(
    'short timers and each new side start at the correct sound position',
    () async {
      final positions = <Duration>[];
      final sound = WorkoutCountdownSound(
        play: (position) async {
          positions.add(position);
        },
        stop: () async {},
      );
      await sound.update(remainingSeconds: 2, active: true);
      await sound.update(remainingSeconds: 0, active: false);
      await sound.update(remainingSeconds: 3, active: true);
      expect(positions, [const Duration(seconds: 1), Duration.zero]);
    },
  );

  test(
    'leaving during a delayed start still stops the sound afterwards',
    () async {
      final started = Completer<void>();
      final events = <String>[];
      final sound = WorkoutCountdownSound(
        play: (_) async {
          events.add('play');
          await started.future;
        },
        stop: () async {
          events.add('stop');
        },
      );
      final playing = sound.update(remainingSeconds: 3, active: true);
      await Future<void>.delayed(Duration.zero);
      final leaving = sound.update(remainingSeconds: 0, active: false);
      started.complete();
      await Future.wait([playing, leaving]);
      expect(events, ['play', 'stop']);
    },
  );
}
