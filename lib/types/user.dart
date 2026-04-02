import 'package:flutter/material.dart';
import 'package:rize/types/config.dart';
import 'package:rize/utils.dart';

class UserData {
  double intensityScore;
  IntensityLevel intensityLevel = IntensityLevel.unknown();
  Time? spinReminderTime;

  UserData({required this.intensityScore, required this.spinReminderTime});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      intensityScore: json['intensityScore']?.toDouble() ?? 0.0,
      spinReminderTime: Time.parse(json['spinReminderTime'] ?? ''),  
    );
  }
}
