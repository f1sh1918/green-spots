import 'package:flutter/material.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';

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

  Future<void> refresh(BuildContext? context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSpots = await _service.fetchSpots();
      _spots = newSpots;
      _isLoading = false;
      notifyListeners();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daten erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (error) {
      _isLoading = false;
      notifyListeners();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $error'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      rethrow;
    }
  }
}
