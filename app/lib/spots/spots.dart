import 'package:app/spots/services/spot_service.dart';
import 'package:app/spots/widgets/spots_detail.dart';
import 'package:app/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';

import 'models/spot.dart';

class Spots extends StatefulWidget {
  const Spots({super.key});

  @override
  State<Spots> createState() => _SpotsState();
}

class _SpotsState extends State<Spots> {
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
        return ListView.separated(
          itemCount: spots.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final spot = spots[index];
            return ListTile(
              leading: spot.image1 != null
                  ? Image.network(
                      spot.image1!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(
                      width: 56,
                      child: Icon(Icons.place, size: 32),
                    ),
              title: Text(spot.title),
              subtitle: SpotsSubtitle(
                spot: spot,
                textStyle: Theme.of(context).textTheme.bodyMedium!,
                sizeFactor: 1.0,
                showLabel: false,
              ),

              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SpotDetailPage(spot: spot)),
              ),
            );
          },
        );
      },
    );
  }
}
