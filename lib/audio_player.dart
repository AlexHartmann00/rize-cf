import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _timerAudio = MethodChannel('de.coachflo.rize/timer_audio');
final AudioPlayer _timerPlayer = AudioPlayer();

Future<void> playTimerSound({Duration position = Duration.zero}) async {
  try {
    await _timerPlayer.stop(); // ensure clean restart
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        await _timerAudio.invokeMethod<bool>('ringerIsNormal') != true)
      return;
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
