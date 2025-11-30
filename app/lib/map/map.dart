import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../spots/models/spot.dart';

class Map extends StatefulWidget {
  final List<Spot> spots;
  const Map({super.key, required this.spots});

  @override
  State<Map> createState() => _MapPageState();
}

class _MapPageState extends State<Map> {
  final _controllerCompleter = Completer<MapLibreMapController>();
  static const _initial = CameraPosition(target: LatLng(48.3705, 10.8978), zoom: 7);
  bool _styleLoaded = false;
  late MapLibreMapController _controller;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: 'https://maps.tuerantuer.org/styles/integreat/style.json',
      initialCameraPosition: _initial,
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
    // 1. GeoJSON-Daten definieren
    Object geoJsonData = spotsToGeoJson(widget.spots);

    // 2. GeoJSON-Quelle hinzufügen
    await _controller.addSource(
      "markers-source",
      GeojsonSourceProperties(data: geoJsonData),
    );

    // 3. Symbol-Layer hinzufügen
    await _controller.addLayer(
      "markers-source",
      "markers-layer",
      SymbolLayerProperties(
        iconImage: "marker_40", // Standard-Icon verwenden
        iconSize: 1.0,
        iconAnchor: "bottom",
        // TODO Font hinzufügen
        // textField: [
        //   "get",
        //   "title" // Zeigt den Titel aus den Properties an
        // ],
        // textOffset: [
        //   "literal",
        //   [0, -2]
        // ],
        // textAnchor: "top",
        // textSize: 12,
        // textColor: "#000000",
      ),
    );
  }

  Object spotsToGeoJson(List<Spot> spots) {
    return {
      "type": "FeatureCollection",
      "features": spots
          .map((spot) => {
                "type": "Feature",
                "properties": {"title": spot.title, "description": spot.note},
                "geometry": {
                  "type": "Point",
                  "coordinates": [spot.long, spot.lat]
                }
              })
          .toList()
    };
  }
}
