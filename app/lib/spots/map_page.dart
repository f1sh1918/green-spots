import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/map/map.dart';
import 'package:flutter/material.dart';

import 'models/spot.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final SpotService _service = SpotService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Spot>>(
      future: _service.fetchSpots(),
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
        final spots = snapshot.data!;
        if (spots.isEmpty) {
          return const Center(child: Text('Keine Spots gefunden'));
        }
        return Map(spots: spots);
      },
    );
  }
}
