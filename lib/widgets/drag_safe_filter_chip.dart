import 'package:flutter/material.dart';

/// A filter chip that only changes on a stationary pointer-up gesture.
///
/// It deliberately avoids Flutter's built-in chip gesture handling so its
/// surrounding scroll view is the only gesture-arena participant.
class DragSafeFilterChip extends StatefulWidget {
  const DragSafeFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
    this.selectedColor,
    this.checkmarkColor,
    this.side,
  });

  final Widget label;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final Color? checkmarkColor;
  final BorderSide? side;

  @override
  State<DragSafeFilterChip> createState() => _DragSafeFilterChipState();
}

class _DragSafeFilterChipState extends State<DragSafeFilterChip> {
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.selected
        ? widget.selectedColor ?? const Color(0xFFD6E5FF)
        : const Color(0xFFF5F7FC);
    final BorderSide border =
        widget.side ??
        BorderSide(
          color: widget.selected
              ? const Color(0xFF8EB9F2)
              : const Color(0xFFD3D7E0),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelected(!widget.selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: StadiumBorder(side: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.avatar case final Widget avatar) ...<Widget>[
              IconTheme(
                data: const IconThemeData(color: Color(0xFF2D3340), size: 18),
                child: avatar,
              ),
              const SizedBox(width: 8),
            ],
            DefaultTextStyle.merge(
              style: const TextStyle(
                color: Color(0xFF343944),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              child: widget.label,
            ),
            if (widget.selected && widget.avatar == null) ...<Widget>[
              const SizedBox(width: 7),
              Icon(
                Icons.check_rounded,
                size: 16,
                color: widget.checkmarkColor ?? const Color(0xFF315F9E),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
