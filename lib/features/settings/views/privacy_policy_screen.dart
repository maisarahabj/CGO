import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PrivacyPage();
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            color: Color(0xFF38358E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: const [
          Text(
            'CampusGO Privacy Policy',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF38358E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This policy explains how CampusGO may collect, use and '
            'protect information when the application is used.',
            style: TextStyle(height: 1.5, color: Color(0xFF555555)),
          ),
          SizedBox(height: 24),

          _PrivacySection(
            title: '1. Account and Profile Information',
            body:
                'Registered users may provide a name, email address, '
                'user identifier, role and account information. Passwords '
                'are handled by the authentication provider and are not '
                'stored as plain text in the CampusGO profile database.',
          ),

          _PrivacySection(
            title: '2. Timetable and Booking Information',
            body:
                'CampusGO may process timetable information and, where '
                'booking functions are used, booking records such as the '
                'selected room, date, time, booking status and associated user.',
          ),

          _PrivacySection(
            title: '3. Navigation Information',
            body:
                'Navigation features may process selected starting points, '
                'destinations, route information, estimated travel time and '
                'accessibility preferences. CampusGO does not require '
                'continuous background GPS tracking for its current indoor-navigation design.',
          ),

          _PrivacySection(
            title: '4. Preferences',
            body:
                'CampusGO may store accessibility, route, notification '
                'and other application preferences required to provide personalised features.',
          ),

          _PrivacySection(
            title: '5. Camera and Attachments',
            body:
                'Camera access may be used for QR scanning and optional '
                'issue-report attachments. QR camera images should not be '
                'retained solely from scanning.',
          ),

          _PrivacySection(
            title: '6. Notifications',
            body:
                'Notification information may be used to deliver class '
                'reminders, booking updates, issue-status updates and other '
                'permitted CampusGO alerts.',
          ),

          _PrivacySection(
            title: '7. Support and Issue Reports',
            body:
                'Issue reports may include descriptions, locations, QR '
                'references, screenshots, photographs, contact details and report status.',
          ),

          _PrivacySection(
            title: '8. Guest Use',
            body:
                'Guests may use supported public navigation functions '
                'without creating an account. Guest information should remain '
                'limited to what is necessary for the permitted feature.',
          ),

          _PrivacySection(
            title: '9. Data Security',
            body:
                'CampusGO uses security measures including authentication, '
                'role-based access, encrypted communication and Supabase '
                'Row-Level Security where configured.',
          ),

          _PrivacySection(
            title: '10. Data Access',
            body:
                'Personal information should only be accessible to authorised '
                'users, administrators and approved service providers where necessary.',
          ),

          _PrivacySection(
            title: '11. Your Choices',
            body:
                'Subject to applicable requirements, users may request '
                'access or correction of their information and may withdraw '
                'optional permissions through their device or application settings.',
          ),

          _PrivacySection(
            title: '12. Changes to this Policy',
            body:
                'This policy may be updated when CampusGO functionality, '
                'service providers or information-handling practices change.',
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A77B4),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
