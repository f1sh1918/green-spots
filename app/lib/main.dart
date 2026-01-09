import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/routes.dart';
import 'package:spots/settings/provider/settings_provider.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/user/user_service.dart';
import 'package:spots/utils/geo_link_helper.dart';
import 'package:spots/utils/location_helper.dart';
import 'package:spots/utils/messenger_utils.dart';

import 'auth/models/settings.dart';

void main() {
  runApp(SettingsProvider(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastLinkProcessed;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initDeepLinks();
    checkUserRole();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      checkUserRole();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SpotsProvider())],
      child: MaterialApp(
        title: 'Green Spots',
        // Für Deep Link Navigation
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          // Material widgets (date picker, dialogs,…)
          GlobalWidgetsLocalizations.delegate,
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

  Future<void> _handleIncomingLink(Uri uri, {required bool isInitial}) async {
    final now = DateTime.now();

    // Doppelte Verarbeitung innerhalb von 3 Sekunde verhindern
    if (_lastLinkProcessed != null && now.difference(_lastLinkProcessed!).inMilliseconds < 3000) {
      debugPrint('Ignoriere doppelten Link: $uri');
      return;
    }

    _lastLinkProcessed = now;
    debugPrint('Deep Link erhalten: $uri');
    final context = navigatorKey.currentContext;
    if (uri.scheme == 'geo' && context != null) {
      final userRole = Provider.of<SettingsModel>(context, listen: false).userRole;
      final canUserAddSpots = allowedRoles.contains(userRole);
      Map<String, dynamic> deepLinkObject = GeoLinkHelper.parseGeoQueryWithPath(uri.path, uri.query);
      if (!canUserAddSpots) {
        showSnackBar(context, 'Für das Erstellen von Spots musst du eingeloggt sein.', Colors.red);
        return;
      }
      if (deepLinkObject['lat'] != null && deepLinkObject['lng'] != null) {
        Map<String, dynamic>? userPosition = await loadUserPosition(context);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AddSpots(
                coordinates: LatLng(deepLinkObject['lat'], deepLinkObject['lng']),
                title: deepLinkObject['title'],
                userPosition: userPosition?['position']),
          ),
        );
      } else {
        showSnackBar(context, 'Ungültiger Link: $uri', Colors.red);
      }
    }
  }

  Future<void> checkUserRole() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final settings = Provider.of<SettingsModel>(context, listen: false);
      final userId = settings.userId;
      if (userId != null && !allowedRoles.contains(settings.userRole)) {
        final newRole = await _userService.getUserRole(userId: userId, context: context, token: settings.token);
        if (context.mounted) {
          Provider.of<SettingsModel>(context, listen: false).setUserRole(userRole: newRole.role);
          if (allowedRoles.contains(newRole.role)) {
            showSnackBar(context, 'Dein Account wurde aktiviert!', Colors.green);
          }
        }
      }
    }
  }
}
