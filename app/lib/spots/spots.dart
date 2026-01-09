import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/settings/provider/spots_provider.dart';

import 'package:spots/spots/widgets/spots_detail.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:spots/utils/distance.dart';

class Spots extends StatefulWidget {
  final Position? userPosition;
  final bool locationPermissionGiven;
  final LocationStatus? locationStatus;

  const Spots({super.key, this.locationPermissionGiven = false, this.userPosition, this.locationStatus});

  @override
  State<Spots> createState() => _SpotsState();
}

class _SpotsState extends State<Spots> {
  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<SettingsModel>(context, listen: false).userRole;
    final canUserAddSpots = allowedRoles.contains(userRole);
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        return Scaffold(
          floatingActionButton: canUserAddSpots
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => AddSpots(
                                userPosition: widget.userPosition,
                              )),
                    );
                  },
                  tooltip: 'Spot hinzufügen',
                  child: Icon(Icons.add),
                )
              : null,
          body: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: spotsProvider.spots.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final spot = spotsProvider.spots[index];
              return ListTile(
                leading: spot.thumbnail != null
                    ? Image.network(
                        spot.thumbnail!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(
                        width: 56,
                        child: Icon(Icons.place, size: 32),
                      ),
                title: Text(spot.title),
                subtitle: SpotsSubtitle(
                  spot: spot,
                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                  sizeFactor: 1.0,
                  showLabel: false,
                ),
                trailing: widget.userPosition != null
                    ? Text('${calculateDistanceFromSpot(spot, widget.userPosition!).toStringAsFixed(1)}km',
                        style: Theme.of(context).textTheme.bodyMedium)
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => SpotDetailPage(
                            currentSpot: spot,
                            userPosition: widget.userPosition,
                            locationPermissionGiven: widget.locationPermissionGiven,
                            locationStatus: widget.locationStatus,
                          )),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
