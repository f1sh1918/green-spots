import 'package:geolocator/geolocator.dart';
import 'package:spots/spots/models/spot.dart';

double calculateDistanceFromSpot(Spot spot, Position userPosition) {
  final distance = Geolocator.distanceBetween(
    spot.lat!,
    spot.long!,
    userPosition!.latitude,
    userPosition!.longitude,
  );
  return distance / 1000;
}
