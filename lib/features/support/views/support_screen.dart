import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import 'faq_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const Color _blue = Color(0xFF176F9E);
  static const Color _darkBlue = Color(0xFF342C86);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: 'Campus',
                    style: TextStyle(color: _darkBlue),
                  ),
                  TextSpan(
                    text: 'GO',
                    style: TextStyle(color: Color(0xFFE31919)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Help & Feedback',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Find answers to common questions or report a problem.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Color(0xFF68727D),
            ),
          ),
          const SizedBox(height: 18),

          _SupportTile(
            icon: Icons.help_outline,
            title: 'Frequently Asked Questions',
            subtitle: 'Browse common CampusGO questions and answers.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _SupportTile(
            icon: Icons.report_problem_outlined,
            title: 'Report an Issue',
            subtitle:
                'Tell us about navigation, room, QR code or application issues.',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.issueReport);
            },
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _blue = Color(0xFF176F9E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB6D4E3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF323A40),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Color(0xFF68727D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _blue),
            ],
          ),
        ),
      ),
    );
  }
}
