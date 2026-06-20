import 'package:flutter/material.dart';
import 'package:rize/helpers/rize_style_helpers.dart';

class RizeCard extends StatelessWidget {
  const RizeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accentColor,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: rizeCardDecoration(
        accentColor: accentColor,
        radius: borderRadius,
      ),
      child: child,
    );
  }
}
