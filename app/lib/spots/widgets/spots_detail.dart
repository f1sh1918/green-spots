// lib/main.dart
import 'package:app/spots/models/spot.dart';
import 'package:flutter/material.dart';

class SpotDetailPage extends StatelessWidget {
  final Spot spot;
  const SpotDetailPage({required this.spot, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(spot.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spot.image1 != null)
              Image.network(
                spot.image1!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 12),
            Text(
              spot.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (spot.space != null)
              Text('Space: ${spot.space}',
                  style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 30),
            // The WP `content.rendered` field is HTML. Use `flutter_html` if you want rich rendering.
            if (spot.fire != null)
              Text('Fire: ${spot.fire}',
                  style: Theme.of(context).textTheme.bodyLarge),
            if (spot.specials != null)
              Text('Specials: ${spot.specials.toString()}',
                  style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}