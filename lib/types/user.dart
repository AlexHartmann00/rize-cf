import 'package:flutter/material.dart';
import 'package:rize/types/config.dart';
import 'package:rize/utils.dart';

class UserData {
  double intensityScore;
  IntensityLevel intensityLevel = IntensityLevel.unknown();
  Time? spinReminderTime;
  bool isPro;
  String? subscriptionStatus;
  DateTime? proAccessUntil;

  UserData({
    required this.intensityScore,
    required this.spinReminderTime,
    this.isPro = false,
    this.subscriptionStatus,
    this.proAccessUntil,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    final DateTime? accessUntil = json['proAccessUntil'] is String
        ? DateTime.tryParse(json['proAccessUntil'] as String)
        : null;
    final bool paidPeriodIsActive =
        accessUntil != null && !accessUntil.isBefore(DateTime.now());
    return UserData(
      intensityScore: json['intensityScore']?.toDouble() ?? 0.0,
      spinReminderTime: Time.parse(json['spinReminderTime'] ?? ''),
      isPro:
          json['isPro'] == true ||
          json['subscriptionStatus'] == 'active' ||
          paidPeriodIsActive,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      proAccessUntil: accessUntil,
    );
  }
}
