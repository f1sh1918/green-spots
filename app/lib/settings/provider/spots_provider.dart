import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/add/models/add_spot.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_cache.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/messenger_utils.dart';

class PendingSpotLocation {
  final double lat;
  final double lng;
  final String? title;
  const PendingSpotLocation({required this.lat, required this.lng, this.title});
}

// Provides spots within the app and can trigger refetch
class SpotsProvider extends ChangeNotifier {
  final SpotService _service = SpotService();
  List<Spot> _spots = [];
  bool _isLoading = false;
  bool _isOffline = false;
  Spot? _activeSpot;
  List<Map<String, dynamic>> _queuedSpots = [];
  PendingSpotLocation? _pendingSpotLocation;
  Position? _userPosition;
  StreamSubscription<Position>? _positionSubscription;

  List<Spot> get spots => _spots;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  Spot? get activeSpot => _activeSpot;
  List<Map<String, dynamic>> get queuedSpots => _queuedSpots;
  int get queuedSpotsCount => _queuedSpots.length;
  PendingSpotLocation? get pendingSpotLocation => _pendingSpotLocation;
  Position? get userPosition => _userPosition;

  void setUserPosition(Position? position) {
    _userPosition = position;
    notifyListeners();
  }

  void startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          _userPosition = position;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void setActiveSpot(Spot? activeSpot) {
    _activeSpot = activeSpot;
    notifyListeners();
  }

  void setPendingSpotLocation(PendingSpotLocation? location) {
    _pendingSpotLocation = location;
    notifyListeners();
  }

  void setSpots(List<Spot> spots) {
    _spots = spots;
    notifyListeners();
  }

  void setOffline(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  Future<void> loadQueue() async {
    _queuedSpots = await SpotCache.loadQueue();
    notifyListeners();
  }

  Future<void> enqueueSpot(Map<String, dynamic> spotData) async {
    await SpotCache.enqueueSpot(spotData);
    _queuedSpots = await SpotCache.loadQueue();
    notifyListeners();
  }

  Future<void> updateQueuedSpot(
    String queueId,
    Map<String, dynamic> spotData,
  ) async {
    await SpotCache.dequeueSpot(queueId);
    await SpotCache.enqueueSpot(spotData);
    _queuedSpots = await SpotCache.loadQueue();
    notifyListeners();
  }

  Future<void> removeFromQueue(String queueId) async {
    await SpotCache.dequeueSpot(queueId);
    _queuedSpots = await SpotCache.loadQueue();
    notifyListeners();
  }

  /// Tries to submit all queued spots. Returns true if queue is now empty.
  Future<bool> processQueue(
    String token,
    BuildContext context,
    Position? userPosition,
  ) async {
    if (_queuedSpots.isEmpty) return true;

    int processed = 0;
    final queue = List<Map<String, dynamic>>.from(_queuedSpots);

    for (final item in queue) {
      final queueId = item['_queueId'] as String;
      final spotData = Map<String, dynamic>.from(item)..remove('_queueId');
      try {
        final spot = AddSpot.fromJson(spotData);
        final success = await _service.addSpot(spot, token, context);
        if (success) {
          await SpotCache.dequeueSpot(queueId);
          processed++;
        }
      } on SocketException {
        break; // still offline
      } catch (_) {
        // malformed entry – remove it
        await SpotCache.dequeueSpot(queueId);
        processed++;
      }
    }

    _queuedSpots = await SpotCache.loadQueue();
    notifyListeners();

    if (processed > 0 && context.mounted) {
      await refresh(context, userPosition);
    }

    return _queuedSpots.isEmpty;
  }

  Future<void> refresh(BuildContext? context, Position? userPosition) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSpots = await _service.fetchSpots();
      _spots = sortSpotsByDistance(newSpots, userPosition);
      _isOffline = false;
      _isLoading = false;
      notifyListeners();

      if (context != null && context.mounted) {
        showSnackBar(
          context,
          'Daten erfolgreich aktualisiert',
          Colors.green,
          Duration(seconds: 1),
        );
      }
    } catch (error) {
      final isNetworkError =
          error is SocketException ||
          error is IOException ||
          error.toString().contains('SocketException') ||
          error.toString().contains('ClientException') ||
          error.toString().contains('Failed host lookup');

      if (isNetworkError) {
        _isOffline = true;
        _isLoading = false;
        final cached = await SpotCache.loadCachedSpots();
        if (cached != null) {
          _spots = sortSpotsByDistance(cached, userPosition);
        }
        notifyListeners();

        if (context != null && context.mounted) {
          showSnackBar(
            context,
            'Kein Internet. Zwischengespeicherte Inhalte werden angezeigt.',
            Colors.orange,
            Duration(seconds: 3),
          );
        }
        return;
      }

      _isOffline = false;
      _isLoading = false;
      notifyListeners();

      if (context != null && context.mounted) {
        showSnackBar(
          context,
          'Fehler beim Laden: $error',
          Colors.red,
          Duration(seconds: 3),
        );
      }

      rethrow;
    }
  }
}
