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

  const Spots({
    super.key,
    this.locationPermissionGiven = false,
    this.userPosition,
    this.locationStatus,
  });

  @override
  State<Spots> createState() => _SpotsState();
}

class _SpotsState extends State<Spots> {
  Widget _buildImagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.green.shade100,
      child: Icon(Icons.park, size: 28, color: Colors.green.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<SettingsModel>(
      context,
      listen: false,
    ).userRole;
    final canUserAddSpots = allowedRoles.contains(userRole);
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        return Scaffold(
          floatingActionButton: canUserAddSpots
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddSpots(userPosition: widget.userPosition),
                      ),
                    );
                  },
                  tooltip: 'Spot hinzufügen',
                  child: Icon(Icons.add),
                )
              : null,
          body: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount:
                spotsProvider.queuedSpotsCount + spotsProvider.spots.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Queued (offline) spots shown first
              if (index < spotsProvider.queuedSpotsCount) {
                final queued = spotsProvider.queuedSpots[index];
                final title = queued['title'] as String? ?? 'Unbekannter Spot';
                return ListTile(
                  leading: Container(
                    width: 56,
                    height: 56,
                    color: Colors.orange.shade50,
                    child: Icon(
                      Icons.upload,
                      size: 28,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  subtitle: Text(
                    'Ausstehend – wird synchronisiert sobald online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  trailing: Icon(
                    Icons.wifi_off,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                );
              }

              final spot =
                  spotsProvider.spots[index - spotsProvider.queuedSpotsCount];
              return ListTile(
                leading: spot.thumbnail != null
                    ? Image.network(
                        spot.thumbnail!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
                title: Text(spot.title),
                subtitle: SpotsSubtitle(
                  spot: spot,
                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                  sizeFactor: 1.0,
                  showLabel: false,
                ),
                trailing: widget.userPosition != null
                    ? Text(
                        '${calculateDistanceFromSpot(spot, widget.userPosition!).toStringAsFixed(1)}km',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SpotDetailPage(
                      currentSpot: spot,
                      userPosition: widget.userPosition,
                      locationPermissionGiven: widget.locationPermissionGiven,
                      locationStatus: widget.locationStatus,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
