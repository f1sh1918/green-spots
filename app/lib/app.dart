import 'package:spots/home.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:flutter/material.dart';

import 'spots/models/spot.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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
        return Home(spots: spots, refetch: _service.fetchSpots);
      },
    );
  }
}
