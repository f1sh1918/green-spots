import 'package:flutter/material.dart';
import 'package:spots/location/determine_position.dart';

Future<Map<String, dynamic>?> loadUserPosition(BuildContext context) async {
  try {
    RequestedPosition? requestedPosition = await determinePosition(
      context,
      requestIfNotGranted: true,
    );

    if (requestedPosition != null) {
      return {
        'position': requestedPosition.position,
        'permissionGiven': true,
        'locationStatus': requestedPosition.locationStatus,
      };
    }
  } catch (e) {
    debugPrint('Fehler beim Laden der Position: $e');
    return {
      'position': null,
      'permissionGiven': false,
      'locationStatus': null,
    };
  }
}
