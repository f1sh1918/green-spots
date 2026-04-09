import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/settings/provider/spots_provider.dart';

class DeleteDraftDialog extends StatelessWidget {
  final String queuedSpotId;

  const DeleteDraftDialog({super.key, required this.queuedSpotId});

  static Future<void> show(BuildContext context, String queuedSpotId) {
    return showDialog<void>(
      context: context,
      builder: (_) => DeleteDraftDialog(queuedSpotId: queuedSpotId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(
        'Entwurf löschen',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Text(
        'Wollen Sie den Entwurf wirklich löschen?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () async {
            await Provider.of<SpotsProvider>(
              context,
              listen: false,
            ).removeFromQueue(queuedSpotId);
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Entwurf löschen'),
        ),
      ],
    );
  }
}
