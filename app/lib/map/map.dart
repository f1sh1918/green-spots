import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final _controllerCompleter = Completer<MapLibreMapController>();
  static const _initial = CameraPosition(target: LatLng(48.3705, 10.8978), zoom: 10);
  bool _styleLoaded = false;
  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: 'https://maps.tuerantuer.org/styles/integreat/style.json',
      initialCameraPosition: _initial,
      onMapCreated: (c) => _controllerCompleter.complete(c),
      onStyleLoadedCallback: () => setState(() => _styleLoaded = true),
    );
  }
}


