import 'package:flutter/material.dart';
import 'package:spots/auth/provider/settings_provider.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const App(),
    );
  }
}
