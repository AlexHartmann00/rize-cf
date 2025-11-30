class UserData {
  double intensityScore;

  UserData({required this.intensityScore});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(intensityScore: json['intensityScore']?.toDouble() ?? 0.0);
  }
}
