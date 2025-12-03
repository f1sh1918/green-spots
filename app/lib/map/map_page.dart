import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/location/location_button.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/spot_dialog.dart';
import 'package:spots/spots/widgets/spots_detail.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/widgets/add_spot_dialog.dart';
import 'package:spots/widgets/map_info_dialog.dart';

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
  late LatLng initialCoordinates = LatLng(
    widget.activeSpot?.lat ?? 48.3705,
    widget.activeSpot?.long ?? 10.8978,
  );
  late final _initial = CameraPosition(
    target: initialCoordinates,
    zoom: widget.activeSpot != null ? detailZoom : 7,
  );

  MapLibreMapController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.activeSpot == null) {
      _animateToUserPosition(widget.userPosition);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstStart = Provider.of<SettingsModel>(context, listen: false).firstMapStart;
      if (firstStart) {
        _showInfoDialog(context);
      }
    });
  }

  Future<void> _animateToUserPosition(Position? position) async {
    if (position != null) {
      final controller = await _controllerCompleter.future;
      final cameraUpdate = CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: detailZoom,
        ),
      );
      await controller.animateCamera(
        cameraUpdate,
        duration: Duration(seconds: 1),
      );
    }

    if (widget.locationStatus == LocationStatus.deniedForever ||
        widget.locationStatus == LocationStatus.denied && mounted) {
      if (mounted) {
        _showFeatureDisabled(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: 'https://maps.tuerantuer.org/styles/integreat/style.json',
          initialCameraPosition: _initial,
          myLocationEnabled: widget.locationPermissionGiven,
          myLocationRenderMode: MyLocationRenderMode.normal,
          attributionButtonMargins: const math.Point(-100, -100),
          onMapLongClick: _onMapClick,
          onMapCreated: (c) {
            _controller = c;
            _controllerCompleter.complete(c);
          },
          onStyleLoadedCallback: () {
            _addGeoJsonMarkers();
          },
        ),
        Positioned(
          bottom: 12,
          right: -4,
          child: LocationButton(
            followUserLocation: widget.locationPermissionGiven,
            bringCameraToUser: () => _animateToUserPosition(widget.userPosition),
          ),
        ),
      ],
    );
  }

  Future<void> _addGeoJsonMarkers() async {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    Object geoJsonData = spotsToGeoJson(spots);

    await _controller!.addSource(
      "markers-source",
      GeojsonSourceProperties(data: geoJsonData),
    );

    await _controller!.addLayer(
      "markers-source",
      "markers-layer",
      SymbolLayerProperties(
        iconImage: "marker_40",
        iconSize: 1.0,
        visibility: 'visible',
        iconAnchor: "bottom",
        iconAllowOverlap: true,
      ),
    );
  }

  Object spotsToGeoJson(List<Spot> spots) {
    return {
      "type": "FeatureCollection",
      "features": spots
          .map(
            (spot) => {
              "type": "Feature",
              "properties": {
                "title": spot.title,
                "description": spot.note,
                "id": spot.id,
              },
              "geometry": {
                "type": "Point",
                "coordinates": [spot.long, spot.lat],
              },
            },
          )
          .toList(),
    };
  }

  Future<void> _onMapClick(math.Point<double> point, clickCoordinates) async {
    final spots = Provider.of<SpotsProvider>(context, listen: false).spots;
    if (!mounted) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final touchTargetSize = pixelRatio * 38.0; // corresponds to 1 cm roughly
    final rect = Rect.fromCenter(
      center: Offset(point.x, point.y),
      width: touchTargetSize,
      height: touchTargetSize,
    );

    final jsonFeatures = await _controller!.queryRenderedFeaturesInRect(
        rect,
        [
          'markers-layer',
        ],
        null);
    final features = jsonFeatures.map((e) => e as Map<String, dynamic>).toList();
    if (features.isNotEmpty) {
      final feature = features[0]['properties'];
      final selectedSpot = spots.firstWhere((spot) => spot.id == feature['id']);

      if (widget.userPosition != null && mounted) {
        final distance = calculateDistanceFromSpot(
          selectedSpot,
          widget.userPosition!,
        );
        _showSpotDialog(context, selectedSpot, distance);
      }
    } else {
      if (mounted) {
        _showAddSpotDialog(
          context,
          clickCoordinates as LatLng,
          widget.userPosition,
        );
      }
    }
  }

  void _showAddSpotDialog(
    BuildContext context,
    LatLng coordinates,
    Position? userPosition,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddSpotDialog(
          coordinates: coordinates,
          userPosition: userPosition,
        );
      },
    );
  }

  void _showSpotDialog(
    BuildContext context,
    Spot selectedSpot,
    double distance,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SpotDialog(
          spot: selectedSpot,
          distance: distance,
          onTap: () {
            Navigator.of(context).pop();
            _showSpotDetails(selectedSpot);
          },
        );
      },
    );
  }

  void _showSpotDetails(Spot selectedSpot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpotDetailPage(
          currentSpot: selectedSpot,
          userPosition: widget.userPosition,
          locationPermissionGiven: widget.locationPermissionGiven,
          locationStatus: widget.locationStatus,
        ),
      ),
    );
  }

  void _showFeatureDisabled(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
        content: Text('Die Standortfreigabe ist deaktiviert.'),
        action: SnackBarAction(
          label: 'Einstellungen',
          onPressed: () async {
            await openSettingsToGrantPermissions(context);
          },
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MapInfoDialog();
      },
    );
  }
}
