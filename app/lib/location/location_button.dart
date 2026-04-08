import 'package:flutter/material.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/location/small_button_spinner.dart';

class LocationIcon extends StatelessWidget {
  final LocationStatus? locationStatus;
  final bool followUserLocation;

  const LocationIcon({
    super.key,
    required this.locationStatus,
    required this.followUserLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (locationStatus == null) {
      return const SmallButtonSpinner();
    }

    final bool hasLocationPermission =
        locationStatus == LocationStatus.always ||
        locationStatus == LocationStatus.whileInUse;
    if (hasLocationPermission) {
      return Icon(
        followUserLocation ? Icons.my_location : Icons.location_searching,
        color: theme.colorScheme.secondary,
      );
    }

    return Icon(Icons.location_disabled, color: theme.colorScheme.error);
  }
}

class LocationButton extends StatefulWidget {
  final Future<void> Function() bringCameraToUser;
  final bool followUserLocation;

  const LocationButton({
    super.key,
    required this.followUserLocation,
    required this.bringCameraToUser,
  });

  @override
  State<StatefulWidget> createState() {
    return _LocationButtonState();
  }
}

class _LocationButtonState extends State<LocationButton> {
  LocationStatus? _locationStatus;

  // Update the location status if followUserLocation changes
  @override
  void didUpdateWidget(LocationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followUserLocation != widget.followUserLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        initializeLocationStatus();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeLocationStatus();
    });
  }

  Future<void> initializeLocationStatus() async {
    LocationStatus status = await checkAndRequestLocationPermission(
      context,
      requestIfNotGranted: false,
    );
    if (mounted) {
      setState(() {
        _locationStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Makes sure that the FAB has
      // has a padding to the right
      //screen edge
      padding: EdgeInsets.only(right: 16),
      child: FloatingActionButton(
        heroTag: 'fab_map_view',
        elevation: 1,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        onPressed: _locationStatus != null ? widget.bringCameraToUser : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: LocationIcon(
            locationStatus: _locationStatus,
            followUserLocation: widget.followUserLocation,
          ),
        ),
      ),
    );
  }
}
