import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';

import '../auth/models/settings.dart';

class AddSpotDialog extends StatelessWidget {
  final LatLng coordinates;

  const AddSpotDialog({super.key, required this.coordinates});

  static Future<void> show(BuildContext context, LatLng coordinates) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AddSpotDialog(coordinates: coordinates);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<SettingsModel>(context, listen: false).token;
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.all(20),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text('Neuen Spot hinzufügen', style: theme.textTheme.headlineSmall),
      content: Text(
        token != null
            ? 'Wollen Sie einen neuen Spot an dieser Stelle hinzufügen?'
            : 'Sie müssen eingeloggt sein, um Spots hinzuzufügen. Gehe Sie zu Einstellungen.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        if (token != null) ...[
          TextButton(
            onPressed: () => {
              Navigator.of(context).pop(),
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddSpots(coordinates: coordinates))),
            },
            child: Text('Spot hinzufügen'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('Schließen'),
        ),
      ],
    );
  }
}
