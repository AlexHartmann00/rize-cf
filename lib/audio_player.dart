import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _timerPlayer = AudioPlayer();

Future<void> playTimerSound({Duration position = Duration.zero}) async {
  try {
    await _timerPlayer.stop(); // ensure clean restart
    await _timerPlayer.play(
      AssetSource('sounds/timer_done.wav'),
      volume: 1.0,
      position: position,
    );
  } catch (e) {
    print('Timer sound failed: $e');
  }
}

Future<void> stopTimerSound() async {
  try {
    await _timerPlayer.stop();
  } catch (e) {
    print('Stopping timer sound failed: $e');
  }
}
