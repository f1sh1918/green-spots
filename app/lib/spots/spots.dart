import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/add/models/add_spot.dart';
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
  final String searchQuery;

  const Spots({
    super.key,
    this.locationPermissionGiven = false,
    this.userPosition,
    this.locationStatus,
    this.searchQuery = '',
  });

  @override
  State<Spots> createState() => _SpotsState();
}

class _SpotsState extends State<Spots> {
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.green.shade100,
      child: Icon(Icons.park, size: 36, color: Colors.green.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<SettingsModel>(context).userRole;
    final canUserAddSpots = allowedRoles.contains(userRole);
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        final query = widget.searchQuery.toLowerCase();
        final filteredSpots =
            (query.isEmpty
                  ? spotsProvider.spots.toList()
                  : spotsProvider.spots
                        .where((s) => s.title.toLowerCase().contains(query))
                        .toList())
              ..sort((a, b) {
                final pos = spotsProvider.userPosition ?? widget.userPosition;
                if (pos != null) {
                  final da = calculateDistanceFromSpot(a, pos);
                  final db = calculateDistanceFromSpot(b, pos);
                  return da.compareTo(db);
                }
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              });

        return Scaffold(
          floatingActionButton: canUserAddSpots
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddSpots(
                          userPosition:
                              spotsProvider.userPosition ?? widget.userPosition,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Spot hinzufügen',
                  child: Icon(Icons.add),
                )
              : null,
          body: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: spotsProvider.queuedSpotsCount + filteredSpots.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Queued (offline) spots shown first
              if (index < spotsProvider.queuedSpotsCount) {
                final queued = spotsProvider.queuedSpots[index];
                final queueId = queued['_queueId'] as String;
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
                    'Ausstehend – tippen zum Bearbeiten',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  trailing: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  onTap: () {
                    final spotData = Map<String, dynamic>.from(queued)
                      ..remove('_queueId');
                    final addSpot = AddSpot.fromJson(spotData);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddSpots(
                          userPosition:
                              spotsProvider.userPosition ?? widget.userPosition,
                          queuedSpot: addSpot,
                          queuedSpotId: queueId,
                        ),
                      ),
                    );
                  },
                );
              }

              final spot =
                  filteredSpots[index - spotsProvider.queuedSpotsCount];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SpotDetailPage(
                      currentSpot: spot,
                      userPosition:
                          spotsProvider.userPosition ?? widget.userPosition,
                      locationPermissionGiven: widget.locationPermissionGiven,
                      locationStatus: widget.locationStatus,
                    ),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 90),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: spot.thumbnail != null
                              ? Image.network(
                                  spot.thumbnail!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.green.shade100,
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 36,
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                )
                              : _buildImagePlaceholder(),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        spot.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if ((spotsProvider.userPosition ??
                                            widget.userPosition) !=
                                        null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${calculateDistanceFromSpot(spot, (spotsProvider.userPosition ?? widget.userPosition)!).toStringAsFixed(1)} km',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SpotsSubtitle(
                                  spot: spot,
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!,
                                  sizeFactor: 0.9,
                                  showLabel: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
