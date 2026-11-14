import 'package:flutter_test/flutter_test.dart';
import 'package:rize/types/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a new account ignores a previous account’s device completion', () {
    SharedPreferences.setMockInitialValues({'anamnesisDone': true});
    final previousAccount = UserData.fromJson({
      'intensityScore': 0.5,
      'anamnesisCompleted': true,
    });
    final newAccount = UserData.fromJson({
      'intensityScore': 0.0,
      'anamnesisCompleted': false,
    });
    expect(previousAccount.anamnesisCompleted, isTrue);
    expect(newAccount.anamnesisCompleted, isFalse);
  });

  test('completed questionnaire stays completed with a zero score', () {
    final account = UserData.fromJson({
      'intensityScore': 0.0,
      'anamnesisCompleted': true,
    });
    expect(account.anamnesisCompleted, isTrue);
  });

  test('older accounts retain their onboarding status', () {
    expect(
      UserData.fromJson({'intensityScore': 0.4}).anamnesisCompleted,
      isTrue,
    );
    expect(
      UserData.fromJson({'intensityScore': 0.0}).anamnesisCompleted,
      isFalse,
    );
  });

  test('explicit incomplete status takes precedence over the legacy score', () {
    expect(
      UserData.fromJson({
        'intensityScore': 0.4,
        'anamnesisCompleted': false,
      }).anamnesisCompleted,
      isFalse,
    );
  });
}
