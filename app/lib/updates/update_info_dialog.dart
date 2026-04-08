import 'package:flutter/material.dart';
import 'package:spots/updates/update_model.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfoDialog extends StatelessWidget {
  final Update updateInfo;
  const UpdateInfoDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, Update updateInfo) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return UpdateInfoDialog(updateInfo: updateInfo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: EdgeInsets.all(20),
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(
        'Neue Version verfügbar',
        style: theme.textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${updateInfo.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Text(
            updateInfo.releaseNotes ?? 'Keine Release Notes verfügbar.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('Schließen'),
        ),
        TextButton(
          onPressed: () => {
            launchUrl(
              Uri.parse(updateInfo.downloadUrl),
              mode: LaunchMode.externalApplication,
            ),
            Navigator.of(context, rootNavigator: true).pop(),
          },
          child: Text('Download'),
        ),
      ],
    );
  }
}
