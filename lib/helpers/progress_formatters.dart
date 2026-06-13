import 'package:flutter/material.dart';
import 'package:rize/types/workout.dart';

String formatScore(double value, {int decimals = 2}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String formatDuration(int totalSeconds) {
  final Duration duration = Duration(seconds: totalSeconds);
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) return '${hours} h ${minutes} min';
  if (hours > 0) return '${hours} h';
  return '${duration.inMinutes} min';
}

String impactLevelLabel(ImpactLevel level) {
  switch (level) {
    case ImpactLevel.low:
      return 'Niedrig';
    case ImpactLevel.medium:
      return 'Mittel';
    case ImpactLevel.high:
      return 'Hoch';
  }
}

Color impactLevelColor(ImpactLevel? level) {
  switch (level) {
    case ImpactLevel.low:
      return const Color(0xFF63E6BE);
    case ImpactLevel.medium:
      return const Color(0xFFFFD166);
    case ImpactLevel.high:
      return const Color(0xFFFF6B6B);
    case null:
      return const Color(0xFF8B93A7);
  }
}
