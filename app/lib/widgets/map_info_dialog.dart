import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../auth/models/settings.dart';

class MapInfoDialog extends StatelessWidget {
  const MapInfoDialog({super.key});

  static Future<void> show(BuildContext context, LatLng coordinates) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return MapInfoDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.all(20),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text('Nutzung der Karte', style: theme.textTheme.headlineSmall),
      content: Text(
        'Die Interaktion mit der Karte erfolgt über einen langen Klick: \n1: Auf einen Marker -> Details ansehen\n2. Auf einen anderen Punkt -> Neuen Spot hinzufügen',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('Okay'),
        ),
        TextButton(
          onPressed: () => {
            Navigator.of(context, rootNavigator: true).pop(),
            Provider.of<SettingsModel>(
              context,
              listen: false,
            ).setFirstStart(enabled: false),
          },
          child: Text('Nicht mehr anzeigen'),
        ),
      ],
    );
  }
}
