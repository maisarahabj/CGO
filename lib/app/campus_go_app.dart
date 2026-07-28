import 'package:flutter/material.dart';

import '../features/auth/controllers/auth_controller.dart';
import 'app_router.dart';
import 'app_theme.dart';

class CampusGoApp extends StatefulWidget {
  const CampusGoApp({super.key});

  @override
  State<CampusGoApp> createState() => _CampusGoAppState();
}

class _CampusGoAppState extends State<CampusGoApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
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
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        authController: _authController,
      ),
    );
  }
}
