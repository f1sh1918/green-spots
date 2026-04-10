import 'package:flutter/material.dart';

class SpotsSubtitleItem extends StatelessWidget {
  final double sizeFactor;
  final Color color;
  final IconData? icon;
  final String? label;
  final String? value;
  final bool isCheck;
  final Color? checkColor;
  final bool isNegative;

  const SpotsSubtitleItem({
    super.key,
    required this.sizeFactor,
    required this.color,
    this.label,
    this.value,
    this.icon,
    this.isCheck = false,
    this.checkColor,
    this.isNegative = false,
  });

  /// Compact chip for list/tile view
  Widget buildChip() {
    final effectiveColor = isNegative ? Colors.grey : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      constraints: const BoxConstraints(minHeight: 28),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon, size: 14 * sizeFactor, color: effectiveColor),
          if (icon != null && value != null) const SizedBox(width: 4),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                fontSize: 12 * sizeFactor,
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Full row for detail view
  Widget buildRow(BuildContext context) {
    final effectiveColor = isNegative ? Colors.grey : color;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: effectiveColor)
              : null,
        ),
        const SizedBox(width: 12),
        if (label != null)
          Text(label!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        if (isCheck)
          Icon(Icons.check, size: 20, color: checkColor ?? effectiveColor)
        else if (value != null)
          Text(
            value!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return label != null ? buildRow(context) : buildChip();
  }
}
