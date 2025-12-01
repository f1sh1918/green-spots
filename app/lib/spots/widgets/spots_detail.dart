// lib/main.dart
import 'package:spots/home.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/image_carousel.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../map/map_page.dart';

class SpotDetailPage extends StatelessWidget {
  final Spot currentSpot;
  final List<Spot> spots;

  const SpotDetailPage({required this.currentSpot, required this.spots, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> imageWidgets = (currentSpot.images ?? [])
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
        actions: [
          IconButton(
            onPressed: () => _launchUrl(currentSpot),
            icon: Icon(Icons.edit),
          )
        ],
        title: Text(currentSpot.title),
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
                    spot: currentSpot,
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                    sizeFactor: 1.2,
                    showLabel: true,
                  ),
                  Divider(height: 50),
                  if (currentSpot.note != null) ...[
                    Text(currentSpot.note!, style: Theme.of(context).textTheme.bodyLarge),
                    Divider(height: 50),
                  ],
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => Home(
                                    activeSpot: currentSpot,
                                    spots: spots,
                                    initialIndex: 0,
                                  )),
                        ),
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

Future<void> _launchUrl(Spot spot) async {
  final Uri url = Uri.parse('https://backend.ballonfabrik.org/wp-admin/post.php?post=${spot.id}&action=edit');
  launchUrl(url, mode: LaunchMode.externalApplication);
}
