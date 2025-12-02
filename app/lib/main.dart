import 'package:flutter/material.dart';
import 'package:spots/routes.dart';
import 'package:spots/settings/provider/settings_provider.dart';

import 'app.dart';

void main() {
  runApp(SettingsProvider(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Spots',
      routes: AppRoutes.routes, // Routes verwenden
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
    );
  }
}
