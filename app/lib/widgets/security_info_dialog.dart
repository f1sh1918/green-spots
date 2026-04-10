import 'package:flutter/material.dart';

void showSecurityInfoDialog(BuildContext context) {
  showDialog(context: context, builder: (ctx) => const _SecurityInfoDialog());
}

class _SecurityInfoDialog extends StatelessWidget {
  const _SecurityInfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Was bedeutet Sicherheit?',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Diese Tipps helfen dir, einen möglichst unauffälligen und sicheren Platz zum Wildcampen zu finden und sollten beim Sicherheitsranking berücksichtigt werden:',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            _TipItem(
              icon: Icons.social_distance,
              title: 'Abstand zu Wegen',
              text:
                  'Suche dir einen Platz, der mindestens 100 Meter von Wanderwegen, Forststraßen oder Pfaden entfernt ist.',
            ),
            _TipItem(
              icon: Icons.visibility_off,
              title: 'Jägerstände meiden',
              text:
                  'Halte mindestens 100 Meter Abstand zu Hochsitzen. Campiere idealerweise hinter einem Hochstand statt davor, um nicht in der Schusslinie zu landen.',
            ),
            _TipItem(
              icon: Icons.forest,
              title: 'Keine Lichtungen',
              text:
                  'Meide offene Flächen. Plätze hinter dichten Nadelbäumen (z. B. Fichten) bieten ganzjährigen Sichtschutz und oft weicheren Boden.',
            ),
            _TipItem(
              icon: Icons.map_outlined,
              title: 'Vorausplanung',
              text:
                  'Nutze Google Earth oder Karten wie Outdooractive, um Geländeformen und Pfade vorab zu prüfen.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Verstanden'),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TipItem({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
