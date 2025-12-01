import 'package:flutter/material.dart';
import 'package:spots/map/map_page.dart';
import 'package:spots/settings/settings.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/spots.dart';

class Home extends StatefulWidget {
  final List<Spot> spots;
  final Spot? activeSpot;
  final Future<List<Spot>> Function()? refetch;
  final int? initialIndex;

  const Home({super.key, required this.spots, this.refetch, this.initialIndex, this.activeSpot});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late int _selectedIndex = widget.initialIndex ?? 1;
  late List<Spot> _currentSpots;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSpots = widget.spots;
  }

  List<Widget> _getPages() {
    return <Widget>[
      MapPage(spots: _currentSpots, activeSpot: widget.activeSpot),
      Spots(spots: _currentSpots),
      const Settings(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleRefresh() async {
    if (widget.refetch != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daten werden aktualisiert...')),
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
            SnackBar(content: Text('Fehler beim Laden: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Green Spots'),
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
