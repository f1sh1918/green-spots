import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/settings/provider/spots_provider.dart';

import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/image_carousel.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:spots/utils/distance.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotDetailPage extends StatefulWidget {
  final Spot currentSpot;
  final Position? userPosition;
  final bool locationPermissionGiven;
  final LocationStatus? locationStatus;

  const SpotDetailPage({
    required this.currentSpot,
    this.userPosition,
    this.locationPermissionGiven = false,
    this.locationStatus,
    super.key,
  });

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  Position? _currentUserPosition;
  bool _currentLocationPermissionGiven = false;
  LocationStatus? _currentLocationStatus;
  final bool _isLoadingPosition = false;

  @override
  void initState() {
    super.initState();
    _currentUserPosition = widget.userPosition;
    _currentLocationPermissionGiven = widget.locationPermissionGiven;
    _currentLocationStatus = widget.locationStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpotsProvider>(context, listen: false).setActiveSpot(widget.currentSpot);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        List<Widget> imageWidgets = (widget.currentSpot.images ?? [])
            .where((url) => url is String && url.trim().isNotEmpty)
            .map<Widget>(
              (url) => Image.network(
                url,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
            .toList();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (context.mounted) {
              Provider.of<SpotsProvider>(context, listen: false).setActiveSpot(null);
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => Home(
                        initialIndex: 1,
                        locationPermissionGiven: _currentLocationPermissionGiven,
                        userPosition: _currentUserPosition,
                        locationStatus: _currentLocationStatus),
                  ),
                  (route) => false);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () => _openEditPage(widget.currentSpot),
                  icon: Icon(Icons.edit),
                ),
              ],
              title: Text(widget.currentSpot.title),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageWidgets.isNotEmpty) ImageCarousel(images: imageWidgets),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 50),
                        SpotsSubtitle(
                          spot: widget.currentSpot,
                          textStyle: Theme.of(context).textTheme.bodyLarge!,
                          sizeFactor: 1.2,
                          showLabel: true,
                        ),
                        Divider(height: 50),
                        if (widget.currentSpot.note != null) ...[
                          Text(
                            widget.currentSpot.note!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Divider(height: 50),
                          if (widget.userPosition != null) ...[
                            Text(
                              '${calculateDistanceFromSpot(widget.currentSpot, widget.userPosition!).toStringAsFixed(1)} km entfernt',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          Divider(height: 50),
                        ],
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isLoadingPosition
                                    ? null
                                    : () => Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) => Home(
                                              initialIndex: 0,
                                              locationPermissionGiven: _currentLocationPermissionGiven,
                                              userPosition: _currentUserPosition,
                                              locationStatus: _currentLocationStatus,
                                            ),
                                          ),
                                          (route) => false,
                                        ),
                                child: Text('Auf Karte anzeigen'),
                              ),
                              SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => _launchMap(
                                  widget.currentSpot.lat,
                                  widget.currentSpot.long,
                                  context,
                                ),
                                child: Text('Navigieren'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _openEditPage(Spot spot) async {
  final Uri url = Uri.parse(
    '$baseUrl/wp-admin/post.php?post=${spot.id}&action=edit',
  );
  launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> _launchMap(double? lat, double? long, BuildContext context) async {
  if (lat == null || long == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Spot konnte nicht in externer Anwendung geöffnet werden.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    final geoUriWithZoom = Uri.parse('geo:$lat,$long?z=14&q=$lat,$long');
    await launchUrl(geoUriWithZoom);
  }
}
