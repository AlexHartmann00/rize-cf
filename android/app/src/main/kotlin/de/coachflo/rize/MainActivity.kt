package de.coachflo.rize

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.coachflo.rize/timer_audio")
            .setMethodCallHandler { call, result ->
                if (call.method == "ringerIsNormal") {
                    val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audio.ringerMode == AudioManager.RINGER_MODE_NORMAL)
                } else {
                    result.notImplemented()
                }
            }
    }
}
