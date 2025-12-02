import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/map/map_page.dart';
import 'package:spots/settings/settings.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/spots.dart';

class Home extends StatefulWidget {
  final List<Spot> spots;
  final bool locationPermissionGiven;
  final Position? userPosition;
  final LocationStatus? locationStatus;
  final Spot? activeSpot;
  final Future<List<Spot>> Function()? refetch;
  final int? initialIndex;

  const Home(
      {super.key,
      required this.spots,
      this.locationPermissionGiven = false,
      this.refetch,
      this.initialIndex,
      this.activeSpot,
      this.locationStatus,
      this.userPosition});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late int _selectedIndex = widget.initialIndex ?? 1;
  late List<Spot> _currentSpots;
  Position? _userPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSpots = widget.spots;
    _userPosition = widget.userPosition;
  }

  Future<void> _handleRefresh() async {
    if (widget.refetch != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daten werden aktualisiert...'), backgroundColor: Colors.orange),
        );
      }
      setState(() {
        _isLoading = true;
      });

      try {
        final newSpots = await widget.refetch!();
        setState(() {
          _currentSpots = newSpots;
          _isLoading = false;
        });
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Laden: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Widget> _getPages() {
    return <Widget>[
      MapPage(
          spots: _currentSpots,
          activeSpot: widget.activeSpot,
          userPosition: _userPosition,
          locationPermissionGiven: widget.locationPermissionGiven,
          locationStatus: widget.locationStatus,
          refresh: _handleRefresh),
      Spots(
          spots: _currentSpots,
          userPosition: _userPosition,
          locationPermissionGiven: widget.locationPermissionGiven,
          locationStatus: widget.locationStatus,
          refresh: _handleRefresh),
      const Settings(),
    ];
  }

  List<String> _getTitles() {
    return ['Karte', 'Übersicht', 'Einstellungen'];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_getTitles()[_selectedIndex]),
        actions: [
          IconButton(onPressed: _handleRefresh, icon: Icon(Icons.refresh)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Spots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.green[800],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: Center(child: _getPages().elementAt(_selectedIndex)),
    );
  }
}
