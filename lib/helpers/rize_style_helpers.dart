import 'package:flutter/material.dart';

const Color rizeBlue = Color(0xFF1670D2);
const Color rizeCyan = Color(0xFF79D5FF);
const Color rizeGreen = Color(0xFF42D77D);
const Color rizeOrange = Color(0xFFFF9857);
const Color rizeRed = Color(0xFFFF5968);
const Color rizeMutedText = Color(0xFFB9C7DB);

BoxDecoration rizeCardDecoration({
  Color? accentColor,
  double radius = 24,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.07),
      ],
    ),
    border: Border.all(color: Colors.white.withOpacity(0.13)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      if (accentColor != null)
        BoxShadow(
          color: accentColor.withOpacity(0.06),
          blurRadius: 28,
        ),
    ],
  );
}

Color rizeImpactColor(double score) {
  final double value = score.clamp(0.0, 1.0);
  if (value <= 0.5) {
    return Color.lerp(rizeGreen, rizeOrange, value * 2) ?? rizeGreen;
  }
  return Color.lerp(rizeOrange, rizeRed, (value - 0.5) * 2) ?? rizeRed;
}
