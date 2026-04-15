import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_cache.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/location_helper.dart';

class _SpotLoadResult {
  final List<Spot> spots;
  final bool isOffline;
  const _SpotLoadResult({required this.spots, required this.isOffline});
}

class App extends StatefulWidget {
  final int initialIndex;
  const App({super.key, this.initialIndex = 1});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final SpotService _service = SpotService();
  Future<List<dynamic>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= Future.wait([_loadSpots(), loadUserPosition(context)]);
  }

  Future<_SpotLoadResult> _loadSpots() async {
    try {
      final spots = await _service.fetchSpots();
      return _SpotLoadResult(spots: spots, isOffline: false);
    } catch (e) {
      // Any network error (SocketException, OSError, ClientException, etc.)
      // falls back to the local cache.
      final cached = await SpotCache.loadCachedSpots();
      return _SpotLoadResult(spots: cached ?? [], isOffline: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final data = snapshot.data!;
        final result = data[0] as _SpotLoadResult;
        final positionData = data[1] as Map<String, dynamic>?;

        final userPosition = positionData?['position'] as Position?;
        final permissionGiven =
            positionData?['permissionGiven'] as bool? ?? false;
        final locationStatus =
            positionData?['locationStatus'] as LocationStatus?;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final spotsProvider = Provider.of<SpotsProvider>(
              context,
              listen: false,
            );
            final token = Provider.of<SettingsModel>(
              context,
              listen: false,
            ).token;
            spotsProvider.setOffline(result.isOffline);
            if (userPosition != null) {
              spotsProvider.setUserPosition(userPosition);
            }
            if (permissionGiven) {
              spotsProvider.startLocationTracking();
            }
            spotsProvider.loadQueue().then((_) {
              if (!result.isOffline &&
                  spotsProvider.queuedSpotsCount > 0 &&
                  token != null &&
                  mounted) {
                spotsProvider.processQueue(token, context, userPosition);
              }
            });
          }
        });

        return Home(
          initialIndex: widget.initialIndex,
          locationPermissionGiven: permissionGiven,
          userPosition: userPosition,
          locationStatus: locationStatus,
          spots: sortSpotsByDistance(result.spots, userPosition),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.park, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Green Spots',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Naturplätze entdecken',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Spots werden geladen...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
