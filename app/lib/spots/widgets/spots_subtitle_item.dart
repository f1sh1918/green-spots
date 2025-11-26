import 'package:flutter/material.dart';

class SpotsSubtitleItem extends StatelessWidget {
  final double sizeFactor;
  final Color color;
  final IconData? icon;
  final String? label;
  final String? value;

  const SpotsSubtitleItem({
    super.key,
    required this.sizeFactor,
    required this.color,
    this.label,
    this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 14 * sizeFactor)),
          const SizedBox(width: 12),
        ],
        if (icon != null) ...[
          Icon(icon, size: 20 * sizeFactor, color: color),
          const SizedBox(width: 4),
        ],
        if (value != null) ...[
          Text(value!, style: TextStyle(fontSize: 14 * sizeFactor)),
          const SizedBox(width: 12),
        ],
      ],
    );
  }
}
