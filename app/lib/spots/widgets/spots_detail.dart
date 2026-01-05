import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/constants/api.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/settings/provider/spots_provider.dart';

import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/image_carousel.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:spots/utils/date_format.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:spots/widgets/delete_spot_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/spot_service.dart';

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
  final _spotsService = SpotService();

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
    final token = Provider.of<SettingsModel>(context, listen: false).token;
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
                if (token != null) ...[
                  IconButton(
                    onPressed: () => _deleteSpot(widget.currentSpot, _spotsService, context, widget.userPosition),
                    icon: Icon(Icons.delete),
                  ),
                ]
              ],
              title: Text(widget.currentSpot.title),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageWidgets.isNotEmpty) ...[
                    ImageCarousel(
                      images: imageWidgets,
                      onImageTap: (index) => _showFullScreenCarousel(context, imageWidgets, index),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                        Text(
                          widget.currentSpot.note!.isNotEmpty ? widget.currentSpot.note! : 'Keine Notiz vorhanden',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Divider(height: 50),
                        if (widget.userPosition != null) ...[
                          Text(
                            '${calculateDistanceFromSpot(widget.currentSpot, widget.userPosition!).toStringAsFixed(1)} km entfernt',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        if (widget.currentSpot.lastVisited != null) ...[
                          Text('Zuletzt besucht: ${convertDateString(widget.currentSpot.lastVisited!)}',
                              style: Theme.of(context).textTheme.bodyLarge),
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

Future<void> _deleteSpot(Spot spot, SpotService spotService, BuildContext context, Position? userPosition) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DeleteSpotDialog(spot: spot, spotService: spotService, userPosition: userPosition);
    },
  );
}

Future<void> _openEditPage(Spot spot) async {
  final Uri url = Uri.parse(
    '$baseUrl/wp-admin/post.php?post=${spot.id}&action=edit',
  );
  launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<void> _launchMap(double? lat, double? long, BuildContext context) async {
  if (lat == null || long == null) {
    showSnackBar(context, 'Spot konnte nicht in externer Anwendung geöffnet werden.', Colors.red);
  } else {
    final geoUriWithZoom = Uri.parse('geo:$lat,$long?z=14&q=$lat,$long');
    await launchUrl(geoUriWithZoom);
  }
}

void _showFullScreenCarousel(BuildContext context, List<Widget> images, int initialIndex) {
  // Extract image URLs from the widgets
  List<String> imageUrls = [];
  for (Widget imageWidget in images) {
    if (imageWidget is Image && imageWidget.image is NetworkImage) {
      imageUrls.add((imageWidget.image as NetworkImage).url);
    }
  }

  // Create fullscreen versions of images
  List<Widget> fullscreenImages = imageUrls
      .map(
        (url) => InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      )
      .toList();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            ImageCarousel(
              images: fullscreenImages,
              isFullscreen: true,
              initialIndex: initialIndex,
            ),
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
