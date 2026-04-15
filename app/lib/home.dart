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
import 'package:spots/user/community_page.dart';
import 'package:spots/user/community_provider.dart';

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

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  late int _selectedIndex = widget.initialIndex ?? 1;
  bool _wasLoggedIn = false;
  Position? _userPosition;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    final communityProvider = Provider.of<CommunityProvider>(
      context,
      listen: false,
    );
    // Map tab → zur aktuellen Position animieren
    if (_selectedIndex == 0) {
      spotsProvider.focusUserLocation();
    }
    // Community tab → Daten neu laden
    if (_selectedIndex == 2 && communityProvider.token != null) {
      communityProvider.load(force: true);
    }
  }

  void switchToMapTab() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userPosition = widget.userPosition;
    _autoLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      if (widget.spots != null) {
        spotsProvider.setSpots(widget.spots!);
      }
    });
  }

  List<Widget> _getPages({required bool isLoggedIn}) {
    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    return <Widget>[
      MapPage(
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
      if (isLoggedIn) const CommunityPage(),
      const Settings(),
    ];
  }

  void _onItemTapped(int index, {required bool isLoggedIn}) {
    setState(() {
      _selectedIndex = index;
    });
    if (isLoggedIn && index == 2) {
      // Community tab — sync token and force refresh
      final token = Provider.of<SettingsModel>(context, listen: false).token;
      final communityProvider = Provider.of<CommunityProvider>(
        context,
        listen: false,
      );
      communityProvider.setToken(token);
      communityProvider.load(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SpotsProvider, SettingsModel>(
      builder: (context, spotsProvider, settings, child) {
        final isLoggedIn = settings.token != null;
        final settingsIndex = isLoggedIn ? 3 : 2;

        // Keep current tab when login state changes (avoid jumping to Community)
        if (isLoggedIn && !_wasLoggedIn && _selectedIndex >= 2) {
          // Community inserted at 2 — shift index right to stay on same page
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() {
              _selectedIndex += 1;
              _wasLoggedIn = true;
            }),
          );
        } else if (!isLoggedIn && _wasLoggedIn) {
          // Community removed — shift index left if needed, go to Settings if on Community
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() {
              if (_selectedIndex == 2)
                _selectedIndex = 2; // Community→Settings
              else if (_selectedIndex > 2)
                _selectedIndex -= 1;
              _wasLoggedIn = false;
            }),
          );
        } else {
          _wasLoggedIn = isLoggedIn;
        }

        // Safety clamp
        if (!isLoggedIn && _selectedIndex == 2) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedIndex = 2),
          );
        }

        if (spotsProvider.pendingSpotLocation != null && _selectedIndex != 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedIndex = 0),
          );
        }

        final titles = isLoggedIn
            ? ['Karte', 'Spots', 'Community', 'Einstellungen']
            : ['Karte', 'Spots', 'Einstellungen'];
        final pages = _getPages(isLoggedIn: isLoggedIn);
        final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

        final isMapTab = safeIndex == 0;
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
                  title: safeIndex == 1
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
                      : Text(titles[safeIndex]),
                  actions: [
                    if (safeIndex == 1) ...[
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
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Karte',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.location_city),
                label: 'Spots',
              ),
              if (isLoggedIn)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Community',
                ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Einstellungen',
              ),
            ],
            selectedItemColor: Colors.green[800],
            type: BottomNavigationBarType.fixed,
            currentIndex: safeIndex,
            onTap: (i) => _onItemTapped(i, isLoggedIn: isLoggedIn),
          ),
          body: Column(
            children: [
              if (spotsProvider.isOffline)
                _buildOfflineBanner(context, settingsIndex),
              Expanded(child: pages.elementAt(safeIndex)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineBanner(BuildContext context, int settingsIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = settingsIndex;
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
    // Sync token to CommunityProvider on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CommunityProvider>(
          context,
          listen: false,
        ).setToken(settings.token);
      }
    });
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
