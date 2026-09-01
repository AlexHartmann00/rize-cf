import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Firebase Functions endpoint. Keep payment credentials exclusively in the
// function environment; the mobile app only sends its Firebase ID token.
const String _checkoutEndpoint =
    'https://europe-west1-rize-11838.cloudfunctions.net/create_pro_checkout';
const String _cancelEndpoint =
    'https://europe-west1-rize-11838.cloudfunctions.net/cancel_pro_subscription';
const String _billingProfileEndpoint =
    'https://europe-west1-rize-11838.cloudfunctions.net/update_billing_profile';

enum ProBillingPeriod { monthly, yearly }

bool proCheckoutAwaitingReturn = false;

class BillingProfile {
  const BillingProfile({
    required this.fullName,
    required this.street,
    required this.postalCode,
    required this.city,
    this.country = 'Deutschland',
  });

  final String fullName;
  final String street;
  final String postalCode;
  final String city;
  final String country;

  factory BillingProfile.fromJson(Map<String, dynamic> json) {
    return BillingProfile(
      fullName: (json['fullName'] as String? ?? '').trim(),
      street: (json['street'] as String? ?? '').trim(),
      postalCode: (json['postalCode'] as String? ?? '').trim(),
      city: (json['city'] as String? ?? '').trim(),
      country: (json['country'] as String? ?? 'Deutschland').trim(),
    );
  }

  Map<String, String> toJson() => <String, String>{
    'fullName': fullName.trim(),
    'street': street.trim(),
    'postalCode': postalCode.trim(),
    'city': city.trim(),
    'country': country.trim().isEmpty ? 'Deutschland' : country.trim(),
  };
}

Future<BillingProfile> loadBillingProfile() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Bitte melde Dich erneut an.');
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final Map<String, dynamic> userData = snapshot.data() ?? <String, dynamic>{};
  final Map<String, dynamic> profile = Map<String, dynamic>.from(
    userData['billingProfile'] as Map? ?? <String, dynamic>{},
  );
  profile.putIfAbsent('fullName', () => user.displayName ?? '');
  return BillingProfile.fromJson(profile);
}

Future<void> saveBillingProfile(BillingProfile profile) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Bitte melde Dich erneut an.');
  final String token = await user.getIdToken() ?? '';
  final response = await http.post(
    Uri.parse(_billingProfileEndpoint),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(profile.toJson()),
  );
  if (response.statusCode != 200) {
    throw StateError('Die Rechnungsdaten konnten nicht gespeichert werden.');
  }
}

Future<void> startProCheckout({
  ProBillingPeriod billingPeriod = ProBillingPeriod.monthly,
}) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Bitte melde Dich erneut an.');
  final String token = await user.getIdToken() ?? '';
  final response = await http.post(
    Uri.parse(_checkoutEndpoint),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, Object?>{
      'locale': 'de_DE',
      'plan': switch (billingPeriod) {
        ProBillingPeriod.monthly => 'rize_pro_monthly',
        ProBillingPeriod.yearly => 'rize_pro_yearly',
      },
    }),
  );
  if (response.statusCode != 200) {
    print(response.body);
    if (response.statusCode == 428) {
      throw StateError('Bitte ergänze zuerst Deine Rechnungsdaten.');
    }
    throw StateError('Der Checkout konnte gerade nicht geöffnet werden.');
  }
  final Uri checkout = Uri.parse(
    jsonDecode(response.body)['checkoutUrl'] as String,
  );
  proCheckoutAwaitingReturn = true;
  if (!await launchUrl(checkout, mode: LaunchMode.externalApplication)) {
    proCheckoutAwaitingReturn = false;
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
    if (response.statusCode == 409) {
      throw StateError('Es ist kein aktives Abo zum Kündigen vorhanden.');
    }
    throw StateError('Das Abo konnte gerade nicht gekündigt werden.');
  }
  final Object? accessUntil = jsonDecode(response.body)['accessUntil'];
  return accessUntil is String ? DateTime.tryParse(accessUntil) : null;
}
