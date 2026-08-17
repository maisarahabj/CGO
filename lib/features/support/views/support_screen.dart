import 'package:flutter/material.dart';

import 'faq_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const Color _blue = Color(0xFF176F9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Help & Feedback',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFB6D4E3)),
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF4F9),
              child: Icon(Icons.help_outline, color: _blue),
            ),
            title: const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'Browse common CampusGO questions and answers.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
