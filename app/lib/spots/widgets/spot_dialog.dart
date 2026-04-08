import 'package:flutter/material.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';

class SpotDialog extends StatelessWidget {
  final Spot spot;
  final double distance;
  final VoidCallback onTap;

  const SpotDialog({
    super.key,
    required this.spot,
    required this.distance,
    required this.onTap,
  });

  static Future<void> show(
    BuildContext context,
    Spot spot,
    double distance,
    VoidCallback onTap,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SpotDialog(spot: spot, distance: distance, onTap: onTap);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${distance.toStringAsFixed(1)} km entfernt',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        SpotsSubtitle(
                          spot: spot,
                          textStyle: Theme.of(context).textTheme.bodyMedium!,
                          sizeFactor: 1.0,
                          showLabel: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
