import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        searchQuery: _searchQuery,
      ),
      const Settings(),
    ];
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
        if (spotsProvider.pendingSpotLocation != null && _selectedIndex != 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedIndex = 0),
          );
        }
        final isMapTab = _selectedIndex == 0;
        return Scaffold(
          extendBodyBehindAppBar: isMapTab,
          appBar: isMapTab
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 0,
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                )
              : AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: _selectedIndex == 1
                      ? TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Tippen, um zu suchen...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      : Text(
                          ['Karte', 'Spots', 'Einstellungen'][_selectedIndex],
                        ),
                  actions: [
                    if (_selectedIndex == 1) ...[
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.search),
                      ),
                    ],
                  ],
                ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_city),
                label: 'Spots',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Einstellungen',
              ),
            ],
            selectedItemColor: Colors.green[800],
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
          body: Column(
            children: [
              if (spotsProvider.isOffline) _buildOfflineBanner(context),
              Expanded(child: _getPages().elementAt(_selectedIndex)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2; // go to settings tab
        });
      },
      child: Container(
        width: double.infinity,
        color: Colors.orange.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Offline-Modus – Tippen für Einstellungen',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
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
