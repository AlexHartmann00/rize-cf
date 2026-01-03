import 'package:rize/types/config.dart';

class UserData {
  double intensityScore;
  IntensityLevel intensityLevel = IntensityLevel.unknown();

  UserData({required this.intensityScore});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(intensityScore: json['intensityScore']?.toDouble() ?? 0.0);
  }
}
