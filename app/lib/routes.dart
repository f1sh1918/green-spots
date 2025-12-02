import 'package:flutter/material.dart';
import 'package:spots/add/add_spots.dart';
import 'app.dart';

class AppRoutes {
  static const String home = '/';
  static const String addSpots = '/add-spots';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const App(),
        addSpots: (context) => const AddSpots(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const App());
      case addSpots:
        return MaterialPageRoute(builder: (_) => const AddSpots());
      default:
        return null;
    }
  }
}
