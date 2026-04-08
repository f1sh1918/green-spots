import 'package:flutter/material.dart';

class LocationServiceDialog extends StatelessWidget {
  const LocationServiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aktiviere Standort'),
      content: Text(
        'Wir benötigen ihre Standortinformation, damit sie die App gut nutzen können',
      ),
      actions: [
        TextButton(
          child: Text('Abbrechen'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('Settings öffnen'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class RationaleDialog extends StatelessWidget {
  final String _rationale;

  const RationaleDialog({super.key, required String rationale})
    : _rationale = rationale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Standortberechtigung'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(_rationale, style: theme.textTheme.bodyLarge),
          Text(
            'Soll noch einmal nach der Berechtigung gefragt werden?',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Erlauben'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        TextButton(
          child: Text('Abbrechen'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
