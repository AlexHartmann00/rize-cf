import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rize/widgets/youtube_consent.dart';
import 'package:rize/youtube.dart';
import 'package:rize/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  testWidgets('consent survives restart and can be withdrawn in settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await loadYoutubeConsent();
    expect(youtubeConsent.value, isNull);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: YoutubeConsentDialog())),
    );
    await tester.tap(find.text('Immer erlauben'));
    await tester.pumpAndSettle();
    youtubeConsent.value = null;
    await loadYoutubeConsent();
    expect(youtubeConsent.value, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.ensureVisible(find.text('YouTube-Videos'));
    await tester.tap(find.text('YouTube-Videos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nur einzeln freigeben'));
    await tester.pumpAndSettle();
    youtubeConsent.value = null;
    await loadYoutubeConsent();
    expect(youtubeConsent.value, isFalse);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              YoutubeVideo(videoId: 'first'),
              YoutubeVideo(videoId: 'second'),
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('Video einmal anzeigen'), findsNWidgets(2));
    expect(find.byType(YoutubePlayer), findsNothing);
  });
}
