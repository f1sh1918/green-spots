import 'package:app/spots/models/spot.dart';
import 'package:app/spots/widgets/spots_subtitle_item.dart';
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
        if (spot.secure != null) ...[
          SpotsSubtitleItem(
            sizeFactor: sizeFactor,
            color: Colors.red,
            icon: Icons.health_and_safety,
            value: spot.secure.toString(),
            label: showLabel ? 'Sicherheit:' : null,
          ),
        ],
        if (spot.space != null) ...[
          SpotsSubtitleItem(
            sizeFactor: sizeFactor,
            color: Colors.blue,
            icon: Icons.festival,
            value: spot.space.toString(),
            label: showLabel ? 'Platz:' : null,
          ),
        ],
      if (spot.swim == true) ...[
        SpotsSubtitleItem(
          sizeFactor: sizeFactor,
          color: Colors.blue,
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
      return Padding(padding: EdgeInsets.only(top:16.0),child:Column(children: items));
    } else {
      return Row(children: items);
    }
  }
}
