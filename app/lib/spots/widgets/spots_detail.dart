// lib/main.dart
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/image_carousel.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';

class SpotDetailPage extends StatelessWidget {
  final Spot spot;

  const SpotDetailPage({required this.spot, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> imageWidgets = (spot.images ?? [])
        .where((url) => url is String && (url as String).trim().isNotEmpty)
        .map<Widget>((url) => Image.network(
              url, // cast from dynamic → String
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(spot.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageWidgets.isNotEmpty) ImageCarousel(images: imageWidgets),
            Padding(
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Divider(height: 50),
                  SpotsSubtitle(
                    spot: spot,
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                    sizeFactor: 1.2,
                    showLabel: true,
                  ),
                  Divider(height: 50),
                  if (spot.note != null) ...[
                    Text(spot.note!, style: Theme.of(context).textTheme.bodyLarge),
                    Divider(height: 50),
                  ],
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () => {},
                        child: Text('Auf Karte anzeigen'),
                      ),
                    ),
                  ),
                ])),
          ],
        ),
      ),
    );
  }
}
