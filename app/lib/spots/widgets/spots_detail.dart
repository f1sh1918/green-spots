// lib/main.dart
import 'package:app/spots/models/spot.dart';
import 'package:app/spots/widgets/image_carousel.dart';
import 'package:app/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';

class SpotDetailPage extends StatelessWidget {
  final Spot spot;

  const SpotDetailPage({required this.spot, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> images = [
      if (spot.image1 != null)
        Image.network(
          spot.image1!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      if (spot.image2 != null)
        Image.network(
          spot.image2!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      if (spot.image3 != null)
        Image.network(
          spot.image3!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(spot.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spot.image1 != null)
              ImageCarousel(images: images, imageIndex: 0),
            SpotsSubtitle(
              spot: spot,
              textStyle: Theme.of(context).textTheme.bodyLarge!,
              sizeFactor: 1.4,
              showLabel: true,
            ),
            Divider(height: 30),
            if(spot.note != null)
            Text('Hinweis:', style:Theme.of(context).textTheme.headlineSmall!),
            Text(spot.note!, style: Theme.of(context).textTheme.bodyLarge!),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: OutlinedButton(
                  onPressed: () => {},
                  child: Text('Auf Karte anzeigen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
