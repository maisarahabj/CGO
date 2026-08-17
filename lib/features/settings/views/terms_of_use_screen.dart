import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Terms of Use',
      intro:
          'These Terms explain the conditions for using the CampusGO application.',
      sections: [
        _LegalSection(
          title: '1. About CampusGO',
          body:
              'CampusGO is an indoor campus-navigation application for '
              'students, lecturers, staff and visitors. It supports destination '
              'search, indoor maps, route guidance and related campus services.',
        ),
        _LegalSection(
          title: '2. Acceptance',
          body:
              'By using CampusGO, you agree to these Terms of Use and the '
              'CampusGO Privacy Policy.',
        ),
        _LegalSection(
          title: '3. Guest and Registered Access',
          body:
              'Guests may use permitted public navigation features. '
              'Registered users may access personalised features such as '
              'timetables, bookings, notifications and saved preferences.',
        ),
        _LegalSection(
          title: '4. Accounts and Roles',
          body:
              'Users must protect their login credentials. Student, lecturer '
              'and administrator roles may have different access levels. '
              'Users must not attempt to access another user’s information or '
              'obtain unauthorised administrator privileges.',
        ),
        _LegalSection(
          title: '5. Permitted Use',
          body:
              'CampusGO must be used lawfully. Users must not interfere with '
              'system security, damage QR checkpoints, misuse map information '
              'or intentionally submit false reports.',
        ),
        _LegalSection(
          title: '6. Navigation Limitations',
          body:
              'Routes are based on available map information and may be '
              'affected by closures, maintenance, restricted areas or physical '
              'conditions. Users should follow official campus signs and instructions.',
        ),
        _LegalSection(
          title: '7. Emergency Use',
          body:
              'CampusGO is not an emergency-response or evacuation service. '
              'During an emergency, follow official alarms, signage and '
              'instructions from authorised personnel.',
        ),
        _LegalSection(
          title: '8. QR and Camera Access',
          body:
              'Camera permission may be requested for approved CampusGO QR '
              'checkpoints or issue-report attachments. Camera access should '
              'not be used for unrelated monitoring.',
        ),
        _LegalSection(
          title: '9. Timetable and Booking Features',
          body:
              'CampusGO may display timetable information and support '
              'campus booking-related functions where implemented. Users '
              'remain responsible for confirming official class information '
              'and booking requirements.',
        ),
        _LegalSection(
          title: '10. Accessibility',
          body:
              'Accessibility Mode attempts to prioritise step-free routes, '
              'lifts and ramps but cannot guarantee that every route remains accessible.',
        ),
        _LegalSection(
          title: '11. User Reports',
          body:
              'Users should provide accurate issue reports and must not '
              'include passwords, confidential records or unnecessary personal data.',
        ),
        _LegalSection(
          title: '12. Service Availability',
          body:
              'CampusGO features may be updated, suspended or temporarily '
              'unavailable because of maintenance, testing or technical issues.',
        ),
        _LegalSection(
          title: '13. Privacy',
          body:
              'Personal information is handled according to the CampusGO '
              'Privacy Policy and applicable Malaysian requirements.',
        ),
        _LegalSection(
          title: '14. Changes to These Terms',
          body:
              'These Terms may be updated when CampusGO functionality, '
              'data practices or legal requirements change.',
        ),
        _LegalSection(
          title: '15. Governing Law',
          body: 'These Terms are governed by the applicable laws of Malaysia.',
        ),
      ],
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            color: Color(0xFF38358E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            intro,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 22),
          ...sections,
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.body});

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
