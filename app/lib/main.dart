import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/routes.dart';
import 'package:spots/settings/provider/settings_provider.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/user/community_provider.dart';
import 'package:spots/user/user_service.dart';
import 'package:spots/utils/geo_link_helper.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastLinkProcessed;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkUserRole());
    _initConnectivityListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      checkUserRole();
      _checkConnectivityOnResume();
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _onConnectivityChanged(results);
    });
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection) {
      // Adapter meldet kein Netz → sofort offline setzen
      spotsProvider.setOffline(true);
      return;
    }

    // Netz wieder vorhanden → tatsächliche Erreichbarkeit prüfen
    final token = Provider.of<SettingsModel>(context, listen: false).token;
    await spotsProvider.refresh(null, null);

    if (!spotsProvider.isOffline &&
        spotsProvider.queuedSpotsCount > 0 &&
        token != null &&
        context.mounted) {
      await spotsProvider.processQueue(token, context, null);
    }
  }

  Future<void> _checkConnectivityOnResume() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
    final token = Provider.of<SettingsModel>(context, listen: false).token;

    // Kein Snackbar beim Resume – Offline/Online-Banner reicht als Feedback
    await spotsProvider.refresh(null, null);

    if (!spotsProvider.isOffline &&
        spotsProvider.queuedSpotsCount > 0 &&
        token != null &&
        context.mounted) {
      await spotsProvider.processQueue(token, context, null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
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
        builder: kIsWeb
            ? (context, child) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: child,
                ),
              )
            : null,
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
    if (_lastLinkProcessed != null &&
        now.difference(_lastLinkProcessed!).inMilliseconds < 3000) {
      debugPrint('Ignoriere doppelten Link: $uri');
      return;
    }

    _lastLinkProcessed = now;
    debugPrint('Deep Link erhalten: $uri');
    final context = navigatorKey.currentContext;
    if (uri.scheme == 'geo' && context != null) {
      final userRole = Provider.of<SettingsModel>(
        context,
        listen: false,
      ).userRole;
      final canUserAddSpots = allowedRoles.contains(userRole);
      Map<String, dynamic> deepLinkObject = GeoLinkHelper.parseGeoQueryWithPath(
        uri.path,
        uri.query,
      );
      if (!canUserAddSpots) {
        showSnackBar(
          context,
          'Für das Erstellen von Spots musst du eingeloggt sein.',
          Colors.red,
        );
        return;
      }
      if (deepLinkObject['lat'] != null && deepLinkObject['lng'] != null) {
        final spotsProvider = Provider.of<SpotsProvider>(
          context,
          listen: false,
        );
        spotsProvider.setPendingSpotLocation(
          PendingSpotLocation(
            lat: deepLinkObject['lat'],
            lng: deepLinkObject['lng'],
            title: deepLinkObject['title'],
          ),
        );
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else {
        showSnackBar(context, 'Ungültiger Link: $uri', Colors.red);
      }
    }
  }

  Future<void> checkUserRole() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final settings = Provider.of<SettingsModel>(context, listen: false);
    final userId = settings.userId;
    if (userId == null) return;

    final result = await _userService.getUserRole(
      userId: userId,
      context: context,
      token: settings.token,
      silent: true,
    );

    // Network / socket error — keep existing role unchanged
    if (result == null || !context.mounted) return;

    // Empty role means the server responded but the user no longer exists
    if (result.role.isEmpty) {
      showSnackBar(
        context,
        'Account nicht mehr verfügbar. Du wirst abgemeldet.',
        Colors.red,
        const Duration(seconds: 4),
      );
      await Provider.of<SettingsModel>(context, listen: false).clearUserData();
      return;
    }

    final oldRole = settings.userRole;
    final newRole = result.role;
    if (oldRole == newRole) return;

    Provider.of<SettingsModel>(
      context,
      listen: false,
    ).setUserRole(userRole: newRole);

    if (!allowedRoles.contains(oldRole) && allowedRoles.contains(newRole)) {
      showSnackBar(context, 'Dein Account wurde aktiviert!', Colors.green);
    } else if (allowedRoles.contains(oldRole) &&
        !allowedRoles.contains(newRole)) {
      showSnackBar(
        context,
        'Deine Berechtigungen wurden geändert.',
        Colors.orange,
        const Duration(seconds: 4),
      );
    }
  }
}
