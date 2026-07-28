import 'package:flutter/material.dart';

import '../features/admin/views/admin_dashboard_screen.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/views/auth_gate.dart';
import '../features/auth/views/login_screen.dart';
import '../features/home/views/guest_home_screen.dart';
import '../features/home/views/user_home_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String guestHome = '/guest';
  static const String userHome = '/home';
  static const String adminDashboard = '/admin';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AuthController authController,
  }) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AuthGate(authController: authController),
        );

      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AuthGate(authController: authController),
        );

      case AppRoutes.guestHome:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GuestHomeScreen(),
        );

      case AppRoutes.userHome:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            if (authController.role == UserRole.user ||
                authController.role == UserRole.admin) {
              return const UserHomeScreen();
            }

            return LoginScreen(authController: authController);
          },
        );

      case AppRoutes.adminDashboard:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            if (authController.role == UserRole.admin) {
              return const AdminDashboardScreen();
            }

            return AuthGate(authController: authController);
          },
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
