import 'package:flutter/material.dart';
import 'package:geolocator_platform_interface/src/models/position.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/constants/constants.dart';

import '../auth/models/settings.dart';

class AddSpotDialog extends StatelessWidget {
  final LatLng coordinates;
  final Position? userPosition;

  const AddSpotDialog({
    super.key,
    required this.coordinates,
    this.userPosition,
  });

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
    final userRole = Provider.of<SettingsModel>(
      context,
      listen: false,
    ).userRole;
    final canUserAddSpots = allowedRoles.contains(userRole);
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.all(20),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(
        'Neuen Spot hinzufügen',
        style: theme.textTheme.headlineSmall,
      ),
      content: Text(
        canUserAddSpots
            ? 'Wollen Sie einen neuen Spot an dieser Stelle hinzufügen?'
            : 'Sie müssen eingeloggt und freigeschaltet sein, um Spots hinzuzufügen.\nÜberprüfe deinen Status in Settings.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('Schließen'),
        ),
        if (canUserAddSpots) ...[
          TextButton(
            onPressed: () => {
              Navigator.of(context).pop(),
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddSpots(
                    coordinates: coordinates,
                    userPosition: userPosition,
                  ),
                ),
              ),
            },
            child: Text('Spot hinzufügen'),
          ),
        ],
      ],
    );
  }
}
