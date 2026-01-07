import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/location_helper.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final SpotService _service = SpotService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      // ✅ Lade sowohl Spots als auch Position parallel
      future: Future.wait([
        _service.fetchSpots(),
        loadUserPosition(context),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '❌ Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final data = snapshot.data!;
        final spots = data[0] as List<Spot>;
        final positionData = data[1] as Map<String, dynamic>?;

        if (spots.isEmpty) {
          return const Center(child: Text('Keine Spots gefunden'));
        }

        // ✅ Daten aus der Map extrahieren
        final userPosition = positionData?['position'] as Position?;
        final permissionGiven = positionData?['permissionGiven'] as bool? ?? false;
        final locationStatus = positionData?['locationStatus'] as LocationStatus?;

        return Home(
            locationPermissionGiven: permissionGiven,
            userPosition: userPosition,
            locationStatus: locationStatus,
            spots: sortSpotsByDistance(spots, userPosition));
      },
    );
  }
}
