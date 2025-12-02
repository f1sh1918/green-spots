import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/spots/widgets/spots_detail.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';

import '../location/determine_position.dart';
import 'models/spot.dart';

class Spots extends StatefulWidget {
  final List<Spot> spots;
  final Position? userPosition;
  final bool locationPermissionGiven;
  final LocationStatus? locationStatus;
  final Future<void> Function() refresh;
  const Spots(
      {super.key,
      required this.spots,
      required this.refresh,
      this.locationPermissionGiven = false,
      this.userPosition,
      this.locationStatus});

  @override
  State<Spots> createState() => _SpotsState();
}

class _SpotsState extends State<Spots> {
  @override
  Widget build(BuildContext context) {
    final token = Provider.of<SettingsModel>(context, listen: false).token;
    return Scaffold(
      floatingActionButton: token != null
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
        itemCount: widget.spots.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final spot = widget.spots[index];
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => SpotDetailPage(
                        currentSpot: spot,
                        spots: widget.spots,
                        userPosition: widget.userPosition,
                        locationPermissionGiven: widget.locationPermissionGiven,
                        locationStatus: widget.locationStatus,
                      )),
            ),
          );
        },
      ),
    );
  }
}
