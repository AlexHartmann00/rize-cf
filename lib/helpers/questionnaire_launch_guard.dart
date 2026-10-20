/// Keeps a questionnaire launch exclusive from loading through route completion.
///
/// Owned by the home page, so rebuilding its content after an app resume cannot
/// start another questionnaire while the existing one is still open.
class QuestionnaireLaunchGuard {
  bool _running = false;

  Future<void> run(Future<void> Function() launch) async {
    if (_running) return;
    _running = true;
    try {
      await launch();
    } finally {
      _running = false;
    }
  }
}
