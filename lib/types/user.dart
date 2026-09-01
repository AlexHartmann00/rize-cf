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
    final String? subscriptionStatus = json['subscriptionStatus'] as String?;
    final DateTime? accessUntil = json['proAccessUntil'] is String
        ? DateTime.tryParse(json['proAccessUntil'] as String)
        : null;
    final bool paidPeriodIsActive =
        accessUntil != null && !accessUntil.isBefore(DateTime.now());
    final bool hasTerminalStatus = <String>{
      'canceled',
      'completed',
      'ended',
      'expired',
      'suspended',
    }.contains(subscriptionStatus);
    return UserData(
      intensityScore: json['intensityScore']?.toDouble() ?? 0.0,
      spinReminderTime: Time.parse(json['spinReminderTime'] ?? ''),
      isPro:
          subscriptionStatus == 'active' ||
          (json['isPro'] == true && !hasTerminalStatus) ||
          paidPeriodIsActive,
      subscriptionStatus: subscriptionStatus,
      proAccessUntil: accessUntil,
    );
  }
}
