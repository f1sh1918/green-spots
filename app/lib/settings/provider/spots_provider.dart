import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/messenger_utils.dart';

// Provides spots within the app and can trigger refetch
class SpotsProvider extends ChangeNotifier {
  final SpotService _service = SpotService();
  List<Spot> _spots = [];
  bool _isLoading = false;
  Spot? _activeSpot;

  List<Spot> get spots => _spots;
  bool get isLoading => _isLoading;
  Spot? get activeSpot => _activeSpot;

  void setActiveSpot(Spot? activeSpot) {
    _activeSpot = activeSpot;
    notifyListeners();
  }

  void setSpots(List<Spot> spots) {
    _spots = spots;
    notifyListeners();
  }

  Future<void> refresh(BuildContext? context, Position? userPosition) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSpots = await _service.fetchSpots();
      _spots = sortSpotsByDistance(newSpots, userPosition);
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
