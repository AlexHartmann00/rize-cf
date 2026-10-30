/// Starts the three-second signal at 3 remaining, and aligns it on resume.
/// Serialize playback changes so a delayed start cannot outlive pause/stop.
class WorkoutCountdownSound {
  WorkoutCountdownSound({required this.play, required this.stop});

  final Future<void> Function(Duration position) play;
  final Future<void> Function() stop;
  Future<void> _pending = Future<void>.value();
  bool _playing = false;

  Future<void> update({required int remainingSeconds, required bool active}) {
    if (!active || remainingSeconds <= 0 || remainingSeconds > 3) {
      if (!_playing) return _pending;
      _playing = false;
      return _pending = _pending.then((_) => stop());
    }
    if (_playing) return _pending;
    _playing = true;
    final position = Duration(seconds: 3 - remainingSeconds);
    return _pending = _pending.then((_) => play(position));
  }
}
