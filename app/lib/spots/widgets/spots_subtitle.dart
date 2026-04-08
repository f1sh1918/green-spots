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
        value: spot.secure.toString(),
        label: showLabel ? 'Sicherheit:' : null,
      ),
      SpotsSubtitleItem(
        sizeFactor: sizeFactor,
        color: Colors.blue,
        icon: Icons.festival,
        value: spot.space.toString(),
        label: showLabel ? 'Platz:' : null,
      ),
      if (spot.swim == true) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.black,
          icon: Icons.pool,
          label: showLabel ? 'Badestelle:' : null,
        ),
      ],
      if (spot.fire == true) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.orange,
          icon: Icons.local_fire_department,
          label: showLabel ? 'Feuerstelle:' : null,
        ),
      ],
      SpotsSubtitleItem(
        sizeFactor: sizeFactor,
        color: Colors.blue,
        icon: Icons.water_drop,
        value: spot.water,
        label: showLabel ? 'Wasser:' : null,
      ),
      if (spot.specials != null && spot.specials!.isNotEmpty) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.red,
          value: spot.specials!.join(' | '),
          label: showLabel ? 'Specials:' : null,
        ),
      ],
    ];
    return buildItems(showLabel, items);
  }

  buildItems(bool showLabel, List<Widget> items) {
    if (showLabel) {
      return Padding(
        padding: EdgeInsets.only(top: 8.0, bottom: 8),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      );
    } else {
      return Wrap(
        spacing: 6.0, // Horizontaler Abstand zwischen den Elementen
        runSpacing: 2.0, // Vertikaler Abstand zwischen den Zeilen
        children: items,
      );
    }
  }
}
