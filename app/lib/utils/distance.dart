import 'package:geolocator/geolocator.dart';
import 'package:spots/spots/models/spot.dart';

double calculateDistanceFromSpot(Spot spot, Position userPosition) {
  final distance = Geolocator.distanceBetween(
    spot.lat!,
    spot.long!,
    userPosition.latitude,
    userPosition.longitude,
  );
  return distance / 1000;
}

List<Spot> sortSpotsByDistance(List<Spot> spots, Position? userPosition) {
  if (userPosition == null) {
    return spots;
  }
  spots.sort((a, b) {
    double? distanceA = calculateDistanceFromSpot(a, userPosition);
    double? distanceB = calculateDistanceFromSpot(b, userPosition);

    return distanceA.compareTo(distanceB);
  });
  return spots;
}
