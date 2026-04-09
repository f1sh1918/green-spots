import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
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

import '../services/comment_service.dart';
import '../services/spot_service.dart';
import 'comments_page.dart';

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
  final _commentService = CommentService();
  int? _commentCount;

  @override
  void initState() {
    super.initState();
    _currentUserPosition = widget.userPosition;
    _currentLocationPermissionGiven = widget.locationPermissionGiven;
    _currentLocationStatus = widget.locationStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      spotsProvider.setActiveSpot(widget.currentSpot);
      if (!spotsProvider.isOffline) {
        _loadCommentCount();
      }
    });
  }

  Future<void> _loadCommentCount() async {
    final count = await _commentService.fetchCommentCount(
      widget.currentSpot.id,
    );
    if (mounted) setState(() => _commentCount = count);
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
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              ),
            )
            .toList();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (context.mounted) {
              Provider.of<SpotsProvider>(
                context,
                listen: false,
              ).setActiveSpot(null);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => Home(
                    initialIndex: 1,
                    locationPermissionGiven: _currentLocationPermissionGiven,
                    userPosition: _currentUserPosition,
                    locationStatus: _currentLocationStatus,
                  ),
                ),
                (route) => false,
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () => _openEditPage(
                    widget.currentSpot,
                    widget.userPosition,
                    context,
                  ),
                  icon: Icon(Icons.edit),
                ),
                if (token != null) ...[
                  IconButton(
                    onPressed: () => _deleteSpot(
                      widget.currentSpot,
                      _spotsService,
                      context,
                      widget.userPosition,
                    ),
                    icon: Icon(Icons.delete),
                  ),
                ],
              ],
              title: Text(widget.currentSpot.title),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageWidgets.isNotEmpty)
                            ImageCarousel(
                              images: imageWidgets,
                              onImageTap: (index) => _showFullScreenCarousel(
                                context,
                                imageWidgets,
                                index,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eigenschaften
                                _SectionCard(
                                  child: SpotsSubtitle(
                                    spot: widget.currentSpot,
                                    textStyle: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!,
                                    sizeFactor: 1.0,
                                    showLabel: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Notiz
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionLabel('Notiz'),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.currentSpot.note!.isNotEmpty
                                            ? widget.currentSpot.note!
                                            : 'Keine Notiz vorhanden',
                                        style:
                                            widget.currentSpot.note!.isNotEmpty
                                            ? Theme.of(
                                                context,
                                              ).textTheme.bodyMedium
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Metadaten
                                _SectionCard(
                                  child: Column(
                                    children: [
                                      if (widget.userPosition != null) ...[
                                        _MetaRow(
                                          icon: Icons.straighten,
                                          color: Colors.teal,
                                          label: 'Entfernung',
                                          value:
                                              '${calculateDistanceFromSpot(widget.currentSpot, widget.userPosition!).toStringAsFixed(1)} km',
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (widget.currentSpot.lastVisited !=
                                          null) ...[
                                        _MetaRow(
                                          icon: Icons.calendar_today_outlined,
                                          color: Colors.orange,
                                          label: 'Zuletzt besucht',
                                          value: convertDateString(
                                            widget.currentSpot.lastVisited!,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      _MetaRow(
                                        icon: Icons.person_outline,
                                        color: Colors.green,
                                        label: 'Erstellt von',
                                        value: widget.currentSpot.author,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoadingPosition
                              ? null
                              : () => Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => Home(
                                      initialIndex: 0,
                                      locationPermissionGiven:
                                          _currentLocationPermissionGiven,
                                      userPosition: _currentUserPosition,
                                      locationStatus: _currentLocationStatus,
                                    ),
                                  ),
                                  (route) => false,
                                ),
                          icon: Icon(Icons.map_outlined),
                          label: Text('Auf Karte anzeigen'),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchMap(
                                  widget.currentSpot.lat,
                                  widget.currentSpot.long,
                                  context,
                                ),
                                icon: Icon(Icons.directions_outlined),
                                label: Text('Navigieren'),
                              ),
                            ),
                            if (!spotsProvider.isOffline) ...[
                              SizedBox(width: 8),
                              Expanded(
                                child: _commentCount == null
                                    ? OutlinedButton.icon(
                                        onPressed: null,
                                        icon: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        label: Text('Kommentare'),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CommentsPage(
                                                spotId: widget.currentSpot.id,
                                                spotTitle:
                                                    widget.currentSpot.title,
                                              ),
                                            ),
                                          );
                                          if (mounted) _loadCommentCount();
                                        },
                                        icon: Icon(Icons.chat_bubble_outline),
                                        label: Text(
                                          'Kommentare ($_commentCount)',
                                        ),
                                      ),
                              ),
                            ],
                          ],
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

Future<void> _deleteSpot(
  Spot spot,
  SpotService spotService,
  BuildContext context,
  Position? userPosition,
) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DeleteSpotDialog(
        spot: spot,
        spotService: spotService,
        userPosition: userPosition,
      );
    },
  );
}

Future<void> _openEditPage(
  Spot spot,
  Position? userPosition,
  BuildContext context,
) async {
  Navigator.of(context).pop();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddSpots(userPosition: userPosition, existingSpot: spot),
    ),
  );
}

Future<void> _launchMap(double? lat, double? long, BuildContext context) async {
  if (lat == null || long == null) {
    showSnackBar(
      context,
      'Spot konnte nicht in externer Anwendung geöffnet werden.',
      Colors.red,
    );
  } else {
    final geoUriWithZoom = Uri.parse('geo:$lat,$long?z=14&q=$lat,$long');
    await launchUrl(geoUriWithZoom);
  }
}

Widget _buildImagePlaceholder() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.green.shade100,
    child: Icon(Icons.park, size: 64, color: Colors.green.shade400),
  );
}

void _showFullScreenCarousel(
  BuildContext context,
  List<Widget> images,
  int initialIndex,
) {
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
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
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

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
