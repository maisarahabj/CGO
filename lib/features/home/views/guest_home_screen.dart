import 'package:flutter/material.dart';

/// Public starting screen for someone without a Supabase login session.
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CampusGO')),
      body: const Center(
        child: Text('Guest home screen'),
      ),
    );
  }
}
