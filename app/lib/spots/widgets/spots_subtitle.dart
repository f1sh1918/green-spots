import 'package:spots/constants/constants.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/spots_subtitle_item.dart';
import 'package:flutter/material.dart';

class SpotsSubtitle extends StatelessWidget {
  final Spot spot;
  final double sizeFactor;
  final TextStyle textStyle;
  final bool showLabel;

  const SpotsSubtitle({
    super.key,
    required this.spot,
    required this.sizeFactor,
    required this.textStyle,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [
      SpotsSubtitleItem(
        sizeFactor: sizeFactor,
        color: Colors.red,
        icon: Icons.health_and_safety,
        value: showLabel
            ? '${spot.secure.toInt()} (${securityLabels[spot.secure.toInt()] ?? ''})'
            : spot.secure.toString(),
        label: showLabel ? 'Sicherheit:' : null,
      ),
      SpotsSubtitleItem(
        sizeFactor: sizeFactor,
        color: Colors.brown,
        icon: Icons.festival,
        value: showLabel
            ? '${spot.space.toInt()} (Anzahl kleiner Zelte)'
            : spot.space.toString(),
        label: showLabel ? 'Platz:' : null,
      ),
      if (spot.swim == true) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.teal,
          icon: Icons.pool,
          label: showLabel ? 'Badestelle:' : null,
          isCheck: showLabel,
        ),
      ],
      if (spot.fire == true) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.orange,
          icon: Icons.local_fire_department,
          label: showLabel ? 'Feuerstelle:' : null,
          isCheck: showLabel,
          checkColor: Colors.black,
        ),
      ],
      SpotsSubtitleItem(
        sizeFactor: sizeFactor,
        color: Colors.blue,
        icon: Icons.water_drop,
        value: spot.water,
        label: showLabel ? 'Wasser:' : null,
        isNegative: spot.water == 'keines',
      ),
      if (spot.specials != null && spot.specials!.isNotEmpty) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.deepPurple,
          icon: Icons.auto_awesome,
          value: spot.specials!.join(' | '),
          label: showLabel ? 'Specials:' : null,
        ),
      ],
    ];
    return buildItems(showLabel, items);
  }

  buildItems(bool showLabel, List<Widget> items) {
    if (showLabel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            items.expand((item) => [item, const SizedBox(height: 10)]).toList()
              ..removeLast(),
      );
    } else {
      return Wrap(spacing: 6.0, runSpacing: 6.0, children: items);
    }
  }
}
