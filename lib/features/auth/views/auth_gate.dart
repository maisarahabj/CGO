import 'package:flutter/material.dart';

import '../../admin/views/admin_dashboard_screen.dart';
import '../../home/views/user_home_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/user_role.dart';
import 'login_screen.dart';

/// Chooses the correct entry screen from the current Supabase session and role.
class AuthGate extends StatelessWidget {
  const AuthGate({required this.authController, super.key});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authController,
      builder: (context, _) {
        if (authController.isLoading) {
          return const _AuthLoadingScreen();
        }

        return switch (authController.role) {
          UserRole.guest => LoginScreen(authController: authController),
          UserRole.user => const UserHomeScreen(),
          UserRole.admin => const AdminDashboardScreen(),
        };
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
