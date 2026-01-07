import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/routes.dart';
import 'package:spots/settings/provider/settings_provider.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/utils/messenger_utils.dart';

void main() {
  runApp(SettingsProvider(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastLinkProcessed;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Initial Link verarbeiten (wenn App geschlossen war)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('Initial Link: $initialLink');

      // Kurz warten bis die App vollständig initialisiert ist
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleIncomingLink(initialLink, isInitial: true);
      });
    }

    // Laufende Links verarbeiten (wenn App bereits läuft)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) => _handleIncomingLink(uri, isInitial: false),
    );
  }

  void _handleIncomingLink(Uri uri, {required bool isInitial}) {
    final now = DateTime.now();

    // Doppelte Verarbeitung innerhalb von 3 Sekunde verhindern
    if (_lastLinkProcessed != null && now.difference(_lastLinkProcessed!).inMilliseconds < 3000) {
      debugPrint('Ignoriere doppelten Link: $uri');
      return;
    }

    _lastLinkProcessed = now;
    debugPrint('Deep Link verarbeitet (Initial: $isInitial): $uri');

    debugPrint('Deep Link erhalten: $uri');
    if (uri.scheme == 'geo') {
      final context = navigatorKey.currentContext;

      // Geo-Koordinaten extrahieren
      final coords = uri.path; // "48.6558371,10.6813134"
      final parts = coords.split(',');

      if (parts.length >= 2) {
        final double? lat = double.tryParse(parts[0]);
        final double? lng = double.tryParse(parts[1]);

        if (lat != null && lng != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AddSpots(coordinates: LatLng(lat, lng)),
            ),
          );
        }
      } else {
        if (context != null) {
          showSnackBar(context, 'Ungültiger Link: $uri', Colors.red);
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SpotsProvider())],
      child: MaterialApp(
        title: 'Green Spots',
        navigatorKey: navigatorKey,
        // Für Deep Link Navigation
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          // Material widgets (date picker, dialogs,…)
          GlobalWidgetsLocalizations.delegate,
          // Generic widget localisation
        ],
        supportedLocales: const [Locale('en'), Locale('de')],
        routes: AppRoutes.routes,
        // Routes verwenden
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
      ),
    );
  }
}
