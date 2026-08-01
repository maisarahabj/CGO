import 'package:flutter/material.dart';

/// Starting screen for a normal authenticated CampusGO user.
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CampusGO')),
      body: const Center(child: Text('Registered-user home screen')),
    );
  }
}
