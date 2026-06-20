import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Firebase Functions endpoint. Keep payment credentials exclusively in the
// function environment; the mobile app only sends its Firebase ID token.
const String _checkoutEndpoint =
    'https://europe-west1-rize-11838.cloudfunctions.net/create_pro_checkout';
const String _cancelEndpoint =
    'https://europe-west1-rize-11838.cloudfunctions.net/cancel_pro_subscription';

Future<void> startProCheckout() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Bitte melde Dich erneut an.');
  final String token = await user.getIdToken() ?? '';
  final response = await http.post(
    Uri.parse(_checkoutEndpoint),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, Object?>{'locale': 'de_DE'}),
  );
  if (response.statusCode != 200) {
    print(response.body);
    throw StateError('Der Checkout konnte gerade nicht geöffnet werden.');
  }
  final Uri checkout = Uri.parse(
    jsonDecode(response.body)['checkoutUrl'] as String,
  );
  if (!await launchUrl(checkout, mode: LaunchMode.externalApplication)) {
    throw StateError('Der Checkout-Link konnte nicht geöffnet werden.');
  }
}

Future<DateTime?> cancelProSubscription() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Bitte melde Dich erneut an.');
  final String token = await user.getIdToken() ?? '';
  final response = await http.post(
    Uri.parse(_cancelEndpoint),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode != 200) {
    print(response.body);
    throw StateError('Das Abo konnte gerade nicht gekündigt werden.');
  }
  final Object? accessUntil = jsonDecode(response.body)['accessUntil'];
  return accessUntil is String ? DateTime.tryParse(accessUntil) : null;
}
