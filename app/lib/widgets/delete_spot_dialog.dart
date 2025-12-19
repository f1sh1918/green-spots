import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';

class DeleteSpotDialog extends StatefulWidget {
  final Spot spot;
  final SpotService spotService;

  const DeleteSpotDialog({
    Key? key,
    required this.spot,
    required this.spotService,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    Spot spot,
    SpotService spotService,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => DeleteSpotDialog(
        spot: spot,
        spotService: spotService,
      ),
    );
  }

  @override
  State<DeleteSpotDialog> createState() => _DeleteSpotDialogState();
}

class _DeleteSpotDialogState extends State<DeleteSpotDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(
        'Spot löschen',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Text(
        'Wollen Sie den Spot wirklich löschen?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _deleteSpot,
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Spot löschen'),
        ),
      ],
    );
  }

  Future<void> _deleteSpot() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);

    final token = Provider.of<SettingsModel>(context, listen: false).token;
    final success = await widget.spotService.deleteSpot(widget.spot.id, context, token);

    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (success) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      await spotsProvider.refresh(context);
    }
  }
}
