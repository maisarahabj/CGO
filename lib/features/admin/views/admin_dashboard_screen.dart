import 'package:flutter/material.dart';

/// Separate starting screen for an authenticated administrator.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CampusGO Admin')),
      body: const Center(child: Text('Admin dashboard screen')),
    );
  }
}
