import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _timerPlayer = AudioPlayer();

Future<void> playTimerSound() async {
  try {
    await _timerPlayer.stop(); // ensure clean restart
    await _timerPlayer.play(AssetSource('sounds/timer_done.wav'), volume: 1.0);
  } catch (e) {
    print('Timer sound failed: $e');
  }
}
