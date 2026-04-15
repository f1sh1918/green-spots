import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/location/location_button.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/comment_service.dart';
import 'package:spots/spots/widgets/comments_page.dart';
import 'package:spots/spots/widgets/spots_detail.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:url_launcher/url_launcher.dart';

double detailZoom = 14;

class MapPage extends StatefulWidget {
  final bool locationPermissionGiven;
  final Spot? activeSpot;
  final Position? userPosition;
  final LocationStatus? locationStatus;

  const MapPage({
    super.key,
    required this.locationPermissionGiven,
    this.activeSpot,
    this.userPosition,
    this.locationStatus,
  });

  @override
  State<MapPage> createState() => _MapPagePageState();
}

class _MapPagePageState extends State<MapPage> {
  final _controllerCompleter = Completer<MapLibreMapController>();
  MapLibreMapController? _controller;
  Spot? _selectedSpot;
  int? _commentCount;
  final _commentService = CommentService();
  Symbol? _pendingMarker;
  LatLng? _pendingCoords;
  String? _pendingTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      final activeSpot = spotsProvider.activeSpot;
      if (activeSpot == null) {
        _animateToUserPosition(widget.userPosition);
      } else {
        _setSelectedSpot(activeSpot, spotsProvider.isOffline);
        _animateToSpot(activeSpot, withSheetOffset: true);
      }
    });
  }

  void _setSelectedSpot(Spot? spot, bool isOffline) {
    setState(() {
      _selectedSpot = spot;
      _commentCount = null;
    });
    if (spot != null && !isOffline) {
      _commentService.fetchCommentCount(spot.id).then((count) {
        if (mounted && _selectedSpot?.id == spot.id) {
          setState(() => _commentCount = count);
        }
      });
    }
  }

  void _closeSheet() {
    setState(() {
      _selectedSpot = null;
      _commentCount = null;
    });
  }

  Future<void> _animateToUserPosition(Position? position) async {
    if (position != null) {
      final controller = await _controllerCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: detailZoom,
          ),
        ),
        duration: const Duration(seconds: 1),
      );
    }
    if (widget.locationStatus == LocationStatus.deniedForever ||
        widget.locationStatus == LocationStatus.denied && mounted) {
      if (mounted) _showFeatureDisabled(context);
    }
  }

  Future<void> _animateToSpot(Spot spot, {bool withSheetOffset = false}) async {
    if (spot.lat == null || spot.long == null) return;
    final controller = await _controllerCompleter.future;

    double targetLat = spot.lat!;
    if (withSheetOffset && mounted) {
      // Shift camera south so spot appears centered in the visible area above sheet.
      // Single animation — no double-centering.
      final renderBox = context.findRenderObject() as RenderBox?;
      final topPadding = MediaQuery.of(context).padding.top;
      final mapHeight = (renderBox?.size.height ?? 400) - topPadding;
      final metersPerPixel =
          (156543.03392 * math.cos(spot.lat! * math.pi / 180)) /
          math.pow(2, detailZoom);
      final latOffset = (mapHeight / 12 * metersPerPixel) / 111320;
      targetLat = spot.lat! - latOffset;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(targetLat, spot.long!), zoom: detailZoom),
      ),
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, _) {
        final pending = spotsProvider.pendingSpotLocation;
        if (pending != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _handlePendingSpotLocation(pending, spotsProvider);
          });
        }
        final sheetOpen = _selectedSpot != null;
        final cardOpen = _pendingCoords != null && !sheetOpen;
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxSheetHeight = constraints.maxHeight / 2;
            return Stack(
              children: [
                MapLibreMap(
                  styleString:
                      'https://maps.tuerantuer.org/styles/integreat/style.json',
                  initialCameraPosition: _initializeCamera(
                    spotsProvider.activeSpot,
                  ),
                  myLocationEnabled: widget.locationPermissionGiven,
                  myLocationRenderMode: MyLocationRenderMode.normal,
                  attributionButtonMargins: const math.Point(-100, -100),
                  compassViewMargins: math.Point(
                    8,
                    MediaQuery.of(context).padding.top + 8,
                  ),
                  onMapClick: _onMapClick,
                  onMapCreated: (c) {
                    _controller = c;
                    _controllerCompleter.complete(c);
                  },
                  onStyleLoadedCallback: _addGeoJsonMarkers,
                ),
                // GPS button + optional bottom sheet/card stacked at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LocationButton(
                          followUserLocation: widget.locationPermissionGiven,
                          bringCameraToUser: () =>
                              _animateToUserPosition(widget.userPosition),
                        ),
                      ),
                      if (sheetOpen)
                        _SpotBottomSheet(
                          spot: _selectedSpot!,
                          maxHeight: maxSheetHeight,
                          userPosition: widget.userPosition,
                          isOffline: spotsProvider.isOffline,
                          commentCount: _commentCount,
                          onClose: _closeSheet,
                          onDetails: () {
                            final spot = _selectedSpot!;
                            _closeSheet();
                            _openSpotDetails(spot);
                          },
                        ),
                      if (cardOpen)
                        _AddSpotCard(
                          userRole: Provider.of<SettingsModel>(
                            context,
                            listen: false,
                          ).userRole,
                          onCancel: _dismissPendingSpot,
                          onConfirm: () {
                            final coords = _pendingCoords!;
                            final title = _pendingTitle;
                            _dismissPendingSpot();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddSpots(
                                  coordinates: coords,
                                  title: title,
                                  userPosition: widget.userPosition,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  CameraPosition _initializeCamera(Spot? activeSpot) {
    return CameraPosition(
      target: LatLng(activeSpot?.lat ?? 48.3705, activeSpot?.long ?? 10.8978),
      zoom: activeSpot != null ? detailZoom : 7,
    );
  }

  Future<void> _onMapClick(math.Point<double> point, clickCoordinates) async {
    if (!mounted) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final touchTargetSize = pixelRatio * 38.0;
    final rect = Rect.fromCenter(
      center: Offset(point.x, point.y),
      width: touchTargetSize,
      height: touchTargetSize,
    );

    // 1. Spot marker tap → open bottom sheet
    if (!mounted) return;
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    final jsonFeatures = await _controller!.queryRenderedFeaturesInRect(rect, [
      'markers-layer',
    ], null);
    final features = jsonFeatures
        .map((e) => e as Map<String, dynamic>)
        .toList();
    if (features.isNotEmpty) {
      final feature = features[0]['properties'];
      final selectedSpot = spots.firstWhere((spot) => spot.id == feature['id']);
      if (!mounted) return;
      if (_selectedSpot?.id == selectedSpot.id) return;
      final isOffline = Provider.of<SpotsProvider>(
        context,
        listen: false,
      ).isOffline;
      _dismissPendingSpot();
      _animateToSpot(selectedSpot, withSheetOffset: true);
      _setSelectedSpot(selectedSpot, isOffline);
      return;
    }

    // 2. Empty tap → close sheet if open, otherwise show add dialog
    if (!mounted) return;
    if (_selectedSpot != null) {
      _closeSheet();
      Provider.of<SpotsProvider>(context, listen: false).setActiveSpot(null);
    } else if (mounted) {
      _showAddSpotCard(clickCoordinates as LatLng, null);
    }
  }

  void _openSpotDetails(Spot spot) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SpotDetailPage(
              currentSpot: spot,
              userPosition: widget.userPosition,
              locationPermissionGiven: widget.locationPermissionGiven,
              locationStatus: widget.locationStatus,
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            final isOffline = Provider.of<SpotsProvider>(
              context,
              listen: false,
            ).isOffline;
            _setSelectedSpot(spot, isOffline);
          }
        });
  }

  Future<void> _addGeoJsonMarkers() async {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    final geoJsonData = spotsToGeoJson(spots);

    await _controller!.addSource(
      'markers-source',
      GeojsonSourceProperties(
        data: geoJsonData,
        cluster: true,
        clusterMaxZoom: 14,
        clusterRadius: 50,
      ),
    );

    await _controller!.addLayer(
      'markers-source',
      'clusters-layer',
      CircleLayerProperties(
        circleColor: '#4CAF50',
        circleRadius: 20,
        circleStrokeWidth: 2,
        circleStrokeColor: '#ffffff',
      ),
      filter: ['has', 'point_count'],
    );

    await _controller!.addLayer(
      'markers-source',
      'cluster-count-layer',
      SymbolLayerProperties(
        textField: ['get', 'point_count_abbreviated'],
        textSize: 14,
        textColor: '#ffffff',
        textFont: ['Noto Sans Bold'],
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      filter: ['has', 'point_count'],
    );

    await _controller!.addLayer(
      'markers-source',
      'markers-layer',
      SymbolLayerProperties(
        iconImage: 'campsite_15',
        iconSize: 1.7,
        visibility: 'visible',
        iconAnchor: 'bottom',
        textFont: ['Noto Sans Bold'],
        iconAllowOverlap: true,
      ),
      enableInteraction: false,
      filter: [
        '!',
        ['has', 'point_count'],
      ],
    );
  }

  Object spotsToGeoJson(List<Spot> spots) {
    return {
      'type': 'FeatureCollection',
      'features': spots
          .map(
            (spot) => {
              'type': 'Feature',
              'properties': {
                'title': spot.title,
                'description': spot.note,
                'id': spot.id,
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [spot.long, spot.lat],
              },
            },
          )
          .toList(),
    };
  }

  Future<void> _dismissPendingSpot() async {
    if (_pendingMarker != null && _controller != null) {
      await _controller!.removeSymbol(_pendingMarker!);
      _pendingMarker = null;
    }
    if (mounted) {
      setState(() {
        _pendingCoords = null;
        _pendingTitle = null;
      });
    }
  }

  Future<void> _handlePendingSpotLocation(
    PendingSpotLocation pending,
    SpotsProvider spotsProvider,
  ) async {
    spotsProvider.setPendingSpotLocation(null);
    final controller = await _controllerCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pending.lat, pending.lng),
          zoom: detailZoom,
        ),
      ),
      duration: const Duration(milliseconds: 500),
    );
    if (mounted) {
      _showAddSpotCard(LatLng(pending.lat, pending.lng), pending.title);
    }
  }

  Future<void> _showAddSpotCard(LatLng coordinates, String? title) async {
    await _dismissPendingSpot();
    _pendingMarker = await _controller?.addSymbol(
      SymbolOptions(
        geometry: coordinates,
        iconImage: 'marker_40_active',
        iconSize: 1.0,
        iconAnchor: 'bottom',
      ),
    );
    if (mounted) {
      setState(() {
        _pendingCoords = coordinates;
        _pendingTitle = title;
      });
    }
  }

  void _showFeatureDisabled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
        content: const Text('Die Standortfreigabe ist deaktiviert.'),
        action: SnackBarAction(
          label: 'Einstellungen',
          onPressed: () async {
            await openSettingsToGrantPermissions(context);
          },
        ),
      ),
    );
  }
}

class _SpotBottomSheet extends StatefulWidget {
  final Spot spot;
  final double maxHeight;
  final Position? userPosition;
  final bool isOffline;
  final int? commentCount;
  final VoidCallback onClose;
  final VoidCallback onDetails;

  const _SpotBottomSheet({
    required this.spot,
    required this.maxHeight,
    required this.userPosition,
    required this.isOffline,
    required this.commentCount,
    required this.onClose,
    required this.onDetails,
  });

  @override
  State<_SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends State<_SpotBottomSheet> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasNote = widget.spot.note != null && widget.spot.note!.isNotEmpty;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          setState(() => _dragOffset += details.delta.dy);
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > 60 || details.velocity.pixelsPerSecond.dy > 300) {
          widget.onClose();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed: drag handle + close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable: title, chips, note
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title + distance
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.spot.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (widget.userPosition != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${calculateDistanceFromSpot(widget.spot, widget.userPosition!).toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        SpotsSubtitle(
                          spot: widget.spot,
                          textStyle: Theme.of(context).textTheme.bodySmall!,
                          sizeFactor: 0.9,
                          showLabel: false,
                        ),
                        if (hasNote) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.spot.note!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.fontSize ??
                                            12) +
                                        2,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Fixed: navigation buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: widget.onDetails,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details anzeigen'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchMap(
                                widget.spot.lat,
                                widget.spot.long,
                                context,
                              ),
                              icon: const Icon(Icons.directions_outlined),
                              label: const Text('Navigieren'),
                            ),
                          ),
                          if (!widget.isOffline) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: widget.commentCount == null
                                  ? OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      label: const Text('Kommentare'),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CommentsPage(
                                                spotId: widget.spot.id,
                                                spotTitle: widget.spot.title,
                                              ),
                                            ),
                                          ),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      label: Text(
                                        'Kommentare (${widget.commentCount})',
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
      ),
    );
  }
}

class _AddSpotCard extends StatelessWidget {
  final String? userRole;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _AddSpotCard({
    required this.userRole,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = allowedRoles.contains(userRole);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.add_location_alt_outlined,
                  color: Colors.green[700],
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    canAdd
                        ? 'Neuen Spot hier erstellen?'
                        : 'Du musst eingeloggt und freigeschaltet sein, um Spots hinzuzufügen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Abbrechen')),
                if (canAdd) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onConfirm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Erstellen'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchMap(double? lat, double? long, BuildContext context) async {
  if (lat == null || long == null) {
    showSnackBar(
      context,
      'Spot konnte nicht in externer Anwendung geöffnet werden.',
      Colors.red,
    );
  } else {
    final geoUri = Uri.parse('geo:$lat,$long?z=14&q=$lat,$long');
    await launchUrl(geoUri);
  }
}
