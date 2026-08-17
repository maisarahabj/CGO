import 'package:flutter/material.dart';
import '../features/timetable/views/my_schedule_screen.dart';
import '../features/admin/views/admin_dashboard_screen.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/views/auth_gate.dart';
import '../features/bookings/views/admin_manage_bookings_screen.dart';
import '../features/home/views/guest_home_screen.dart';
import '../features/home/views/user_home_screen.dart';
import '../features/navigation/models/node_model.dart';
import '../features/navigation/views/admin_manage_navigation_screen.dart';
import '../features/navigation/views/qr_scanner_screen.dart';
import '../features/notifications/views/admin_manage_notifications_screen.dart';
import '../features/notifications/views/notifications_screen.dart';
import '../features/profile/views/admin_manage_users_screen.dart';
import '../features/profile/views/edit_profile_screen.dart';
import '../features/settings/views/settings_screen.dart';
import '../features/support/views/admin_manage_issue_reports_screen.dart';
import '../features/support/views/privacy_legal_help_screen.dart';
import '../features/support/views/support_screen.dart';
import '../features/timetable/views/admin_manage_timetable_screen.dart';
import '../features/timetable/views/timetable_screen.dart';
import 'app_routes.dart';

export 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AuthController authController,
  }) {
    switch (settings.name) {
      case AppRoutes.home:
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
        final initialDestinationNodeId = settings.arguments is String
            ? (settings.arguments as String).trim()
            : null;

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => authController.role == UserRole.user
              ? UserHomeScreen(
                  authController: authController,
                  initialDestinationNodeId: initialDestinationNodeId,
                )
              : AuthGate(authController: authController),
        );

      case AppRoutes.adminDashboard:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => authController.role == UserRole.admin
              ? AdminDashboardScreen(authController: authController)
              : AuthGate(authController: authController),
        );

      case AppRoutes.notifications:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => authController.role == UserRole.user
              ? const NotificationsScreen()
              : AuthGate(authController: authController),
        );

      case AppRoutes.timetable:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            if (authController.role == UserRole.user) {
              return const MyScheduleScreen();
            }

            if (authController.role == UserRole.guest) {
              return const TimetableScreen(guestMode: true);
            }

            return AuthGate(authController: authController);
          },
        );

      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case AppRoutes.support:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SupportScreen(),
        );

      case AppRoutes.editProfile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final profile = authController.profile;
            if (authController.role != UserRole.guest && profile != null) {
              return EditProfileScreen(profile: profile);
            }

            return AuthGate(authController: authController);
          },
        );

      case AppRoutes.qrScanner:
        return MaterialPageRoute<NodeModel>(
          settings: settings,
          builder: (_) => const QrScannerScreen(),
        );

      case AppRoutes.adminNotifications:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageNotificationsScreen(),
        );

      case AppRoutes.adminBookingRequests:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageBookingsScreen(),
        );

      case AppRoutes.adminRoomAvailability:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageTimetableScreen(),
        );

      case AppRoutes.adminMapManagement:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageNavigationScreen(
            pageTitle: 'Map Management',
          ),
        );

      case AppRoutes.adminRouteManagement:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageNavigationScreen(
            pageTitle: 'Route Management',
          ),
        );

      case AppRoutes.adminIssueReports:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageIssueReportsScreen(),
        );

      case AppRoutes.adminQrCheckpoints:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageNavigationScreen(
            pageTitle: 'QR Checkpoints',
          ),
        );

      case AppRoutes.adminUserProfiles:
        return _adminRoute(
          settings: settings,
          authController: authController,
          screen: const AdminManageUsersScreen(),
        );

      case AppRoutes.privacyLegalHelp:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PrivacyLegalHelpScreen(),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _UnknownRouteScreen(),
        );
    }
  }

  static Route<dynamic> _adminRoute({
    required RouteSettings settings,
    required AuthController authController,
    required Widget screen,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => authController.role == UserRole.admin
          ? screen
          : AuthGate(authController: authController),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
