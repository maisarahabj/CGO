import 'package:flutter/material.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/services/auth_service.dart';
import 'app_router.dart';
import 'app_theme.dart';

class CampusGoApp extends StatefulWidget {
  const CampusGoApp({this.authService, super.key});

  /// In the real application this remains null, so AuthController creates
  /// the real Supabase AuthService.
  ///
  /// Widget tests can provide a fake AuthService to avoid connecting to
  /// Supabase.
  final AuthService? authService;

  @override
  State<CampusGoApp> createState() => _CampusGoAppState();
}

class _CampusGoAppState extends State<CampusGoApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();

    _authController = AuthController(authService: widget.authService);
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      onGenerateRoute: (settings) {
        return AppRouter.onGenerateRoute(
          settings,
          authController: _authController,
        );
      },
    );
  }
}
