import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final SpotService _service = SpotService();
  final Connectivity _connectivity = Connectivity();

  bool _hasInternet = true;
  bool _isInitialized = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    // Initiale Verbindungsüberprüfung
    _hasInternet = await _checkInternetConnection();

    // Auf Verbindungsänderungen hören
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        bool hasConnection = await _checkInternetConnection();
        if (mounted && hasConnection != _hasInternet) {
          setState(() {
            _hasInternet = hasConnection;
          });
        }
      },
    );

    setState(() {
      _isInitialized = true;
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Zusätzliche Überprüfung durch einen echten Internet-Request
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasInternet) {
      return _buildNoInternetScreen();
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _service.fetchSpots(),
        _loadUserPosition(context),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // Prüfen ob der Fehler durch fehlende Internetverbindung verursacht wurde
          if (_isNetworkError(snapshot.error.toString())) {
            return _buildNoInternetScreen();
          }

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Es ist ein Fehler aufgetreten',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Trigger rebuild
                        });
                      },
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final spots = data[0] as List<Spot>;
        final positionData = data[1] as Map<String, dynamic>?;

        if (spots.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Keine Spots gefunden')),
          );
        }

        final userPosition = positionData?['position'] as Position?;
        final permissionGiven = positionData?['permissionGiven'] as bool? ?? false;
        final locationStatus = positionData?['locationStatus'] as LocationStatus?;

        return Home(
          locationPermissionGiven: permissionGiven,
          userPosition: userPosition,
          locationStatus: locationStatus,
          spots: spots,
        );
      },
    );
  }

  Widget _buildNoInternetScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: 80,
                  color: Colors.red.shade400,
                ),
              ),

              const SizedBox(height: 32),

              // Titel
              Text(
                'Keine Internetverbindung',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Beschreibung
              Text(
                'Diese Anwendung benötigt eine Internetverbindung, um ordnungsgemäß zu funktionieren. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Erneut versuchen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tipps
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipps:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildTip('• Überprüfen Sie Ihre WLAN-Verbindung'),
                    _buildTip('• Überprüfen Sie Ihre mobilen Daten'),
                    _buildTip('• Stellen Sie sicher, dass Sie sich in einem Bereich mit gutem Signal befinden'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _handleRetry() async {
    setState(() {
      _hasInternet = true; // Optimistic update für bessere UX
    });

    // Kurze Verzögerung und dann Verbindung prüfen
    await Future.delayed(const Duration(milliseconds: 500));

    final hasConnection = await _checkInternetConnection();

    if (mounted) {
      setState(() {
        _hasInternet = hasConnection;
      });
    }
  }

  bool _isNetworkError(String errorMessage) {
    final networkErrorKeywords = [
      'netzwerkfehler',
      'network',
      'connection',
      'timeout',
      'unreachable',
      'failed to connect',
      'no internet',
    ];

    final lowerError = errorMessage.toLowerCase();
    return networkErrorKeywords.any((keyword) => lowerError.contains(keyword));
  }

  Future<Map<String, dynamic>?> _loadUserPosition(BuildContext context) async {
    try {
      RequestedPosition? requestedPosition = await determinePosition(
        context,
        requestIfNotGranted: true,
      );

      if (requestedPosition != null) {
        return {
          'position': requestedPosition.position,
          'permissionGiven': true,
          'locationStatus': requestedPosition.locationStatus,
        };
      }

      return {
        'position': null,
        'permissionGiven': false,
        'locationStatus': null,
      };
    } catch (e) {
      debugPrint('Fehler beim Laden der Position: $e');
      return {
        'position': null,
        'permissionGiven': false,
        'locationStatus': null,
      };
    }
  }
}
