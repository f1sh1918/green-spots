import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/onboarding/onboarding_page.dart';
import 'app.dart';

class AppRoutes {
  static const String home = '/';
  static const String addSpots = '/add-spots';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const _StartupPage(),
    addSpots: (context) => const AddSpots(),
  };
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    if (!settings.hasSeenOnboarding) {
      return const OnboardingPage();
    }
    return const App();
  }
}
