import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/services/auth.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/map/map_page.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/settings/settings.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/spots.dart';

import 'auth/models/settings.dart';

class Home extends StatefulWidget {
  final List<Spot>? spots;
  final bool locationPermissionGiven;
  final Position? userPosition;
  final LocationStatus? locationStatus;
  final int? initialIndex;

  const Home({
    super.key,
    this.spots,
    this.locationPermissionGiven = false,
    this.initialIndex,
    this.locationStatus,
    this.userPosition,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _authService = AuthService();
  late int _selectedIndex = widget.initialIndex ?? 1;
  Position? _userPosition;

  void switchToMapTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _userPosition = widget.userPosition;
    _autoLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      if (widget.spots != null) {
        spotsProvider.setSpots(widget.spots!);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    await spotsProvider.refresh(context, _userPosition);
  }

  List<Widget> _getPages() {
    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    return <Widget>[
      MapPage(
        // ensures that the map will be updated in the spot length change
        key: ValueKey('map_${spotsProvider.spots.length}'),
        activeSpot: spotsProvider.activeSpot,
        userPosition: _userPosition,
        locationPermissionGiven: widget.locationPermissionGiven,
        locationStatus: widget.locationStatus,
      ),
      Spots(
        userPosition: _userPosition,
        locationPermissionGiven: widget.locationPermissionGiven,
        locationStatus: widget.locationStatus,
      ),
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
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(_getTitles()[_selectedIndex]),
            actions: [
              if (_selectedIndex == 1) ...[
                IconButton(
                  onPressed: spotsProvider.isLoading ? null : _handleRefresh,
                  icon: spotsProvider.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh),
                ),
              ],
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
      },
    );
  }

  _autoLogin() {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    if (settings.refreshToken != null &&
        _authService.isTokenExpired(settings.expireLogin) &&
        mounted) {
      _authService.loginWithRefreshToken(
        context: context,
        token: settings.refreshToken!,
      );
    }
  }
}
