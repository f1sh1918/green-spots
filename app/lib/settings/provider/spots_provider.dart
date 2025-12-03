import 'package:flutter/material.dart';
import 'package:spots/spots/models/spot.dart';

// Provides spots within the app and can trigger refetch
class SpotsProvider extends ChangeNotifier {
  List<Spot> _spots = [];
  bool _isLoading = false;
  Future<List<Spot>> Function()? _refetchFunction;

  List<Spot> get spots => _spots;
  bool get isLoading => _isLoading;

  void setRefetchFunction(Future<List<Spot>> Function()? refetch) {
    _refetchFunction = refetch;
  }

  void setSpots(List<Spot> spots) {
    _spots = spots;
    notifyListeners();
  }

  Future<void> refresh(BuildContext? context) async {
    if (_refetchFunction == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newSpots = await _refetchFunction!();
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
