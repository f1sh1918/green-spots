import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:spots/spots/widgets/spots_detail.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';

import '../spots/models/spot.dart';

class MapPage extends StatefulWidget {
  final List<Spot> spots;
  final Spot? activeSpot;
  const MapPage({super.key, required this.spots, this.activeSpot});

  @override
  State<MapPage> createState() => _MapPagePageState();
}

class _MapPagePageState extends State<MapPage> {
  final _controllerCompleter = Completer<MapLibreMapController>();
  late LatLng initialCoordinates = LatLng(widget.activeSpot?.lat ?? 48.3705, widget.activeSpot?.long ?? 10.8978);
  late final _initial = CameraPosition(target: initialCoordinates, zoom: widget.activeSpot != null ? 14 : 7);
  bool _styleLoaded = false;

  late MapLibreMapController _controller;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: 'https://maps.tuerantuer.org/styles/integreat/style.json',
      initialCameraPosition: _initial,
      // Hide non working attributes
      attributionButtonMargins: const math.Point(-100, -100),
      onMapLongClick: _onMapClick,
      onMapCreated: (c) {
        _controller = c;
        _controllerCompleter.complete(c);
      },
      onStyleLoadedCallback: () {
        setState(() => _styleLoaded = true);
        _addGeoJsonMarkers();
      },
    );
  }

  Future<void> _addGeoJsonMarkers() async {
    Object geoJsonData = spotsToGeoJson(widget.spots);

    await _controller.addSource(
      "markers-source",
      GeojsonSourceProperties(data: geoJsonData),
    );

    await _controller.addLayer(
      "markers-source",
      "markers-layer",
      SymbolLayerProperties(
          iconImage: "marker_40", iconSize: 1.0, visibility: 'visible', iconAnchor: "bottom", iconAllowOverlap: true),
    );

  }

  Object spotsToGeoJson(List<Spot> spots) {
    return {
      "type": "FeatureCollection",
      "features": spots
          .map((spot) => {
                "type": "Feature",
                "properties": {"title": spot.title, "description": spot.note, "id": spot.id},
                "geometry": {
                  "type": "Point",
                  "coordinates": [spot.long, spot.lat]
                }
              })
          .toList()
    };
  }

  Future<void> _onMapClick(math.Point<double> point, clickCoordinates) async {
    final controller = _controller;
    if (!mounted) return;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final touchTargetSize = pixelRatio * 38.0; // corresponds to 1 cm roughly
    final rect = Rect.fromCenter(center: Offset(point.x, point.y), width: touchTargetSize, height: touchTargetSize);

    final jsonFeatures = await controller.queryRenderedFeaturesInRect(rect, ['markers-layer'], null);
    final features = jsonFeatures.map((e) => e as Map<String, dynamic>).toList();
    if (features.isNotEmpty) {
      final feature = features[0]['properties'];
      final selectedSpot = widget.spots.firstWhere((spot) => spot.id == feature['id']);

      if (selectedSpot != null) {
        _showSpotDialog(context, selectedSpot, widget.spots);
      }
    }
  }

  void _showSpotDialog(BuildContext context, Spot selectedSpot, List<Spot> spots) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedSpot.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const Divider(),
                SpotsSubtitle(
                  spot: selectedSpot,
                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                  sizeFactor: 1.0,
                  showLabel: false,
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Schließen'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSpotDetails(selectedSpot!, spots);
                      },
                      child: const Text('Details anzeigen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpotDetails(Spot selectedSpot, List<Spot> spots) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpotDetailPage(currentSpot: selectedSpot, spots: spots),
      ),
    );
  }
}
