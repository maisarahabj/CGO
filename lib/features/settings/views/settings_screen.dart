import 'package:flutter/material.dart';

/// Temporary view used to verify that drawer navigation is connected.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Remove this text later. This text shows that the linking works. '
            'The Settings page interface will go here. - Mai',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
