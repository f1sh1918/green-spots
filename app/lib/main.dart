import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:spots/routes.dart';
import 'package:spots/settings/provider/settings_provider.dart';
import 'package:spots/settings/provider/spots_provider.dart';

void main() {
  runApp(SettingsProvider(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
      ],
      child: MaterialApp(
        title: 'Green Spots',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate, // Material widgets (date picker, dialogs,…)
          GlobalWidgetsLocalizations.delegate, // Generic widget localisation
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('de'),
        ],
        routes: AppRoutes.routes, // Routes verwenden
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
      ),
    );
  }
}
