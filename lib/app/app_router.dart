import 'package:flutter/material.dart';

import '../features/home/views/home_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String guestHome = '/guest';
  static const String userHome = '/home';
  static const String adminDashboard = '/admin';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // TODO: Before adding the routes above to this switch, connect the router
    // to AuthController. The route guard must apply these rules:
    //
    // guest  -> public routes only
    // user   -> public routes and registered-user routes
    // admin  -> public routes, registered-user routes, and admin routes
    //
    // Supabase RLS must enforce the same permissions at database level.
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _UnknownRouteScreen(),
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
