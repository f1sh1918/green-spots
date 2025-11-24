import 'package:app/spots/models/spot.dart';
import 'package:flutter/material.dart';

class SpotsSubtitle extends StatelessWidget {
  final Spot spot;
  const SpotsSubtitle({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (spot.fire == true) ...[
    const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
          const SizedBox(width: 12),
      ],
        if (spot.swim == true) ...[
          const Icon(Icons.pool, size: 16, color: Colors.blue),
          const SizedBox(width: 12),
        ],
        if (spot.secure != null) ...[
          const Icon(Icons.health_and_safety, size: 16, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            '${spot.secure}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 12),
        ],
        if (spot.specials != null) ...[
          Text(spot.specials!.join(' | '),
              style: Theme.of(context).textTheme.bodyMedium),
    ],
        ]
    );
  }
}
