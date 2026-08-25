import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: 'Privacy Policy',
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(22, 24, 22, 36),
                children: [
                  Text(
                    'CampusGO Privacy Policy',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF115388),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This policy explains how CampusGO may collect, use and '
                    'protect information when the application is used.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.5,
                      height: 1.55,
                      color: Color(0xFF555555),
                    ),
                  ),
                  SizedBox(height: 26),
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
                        'continuous background GPS tracking for its current '
                        'indoor-navigation design.',
                  ),
                  _PrivacySection(
                    title: '4. Preferences',
                    body:
                        'CampusGO may store accessibility, route, notification '
                        'and other application preferences required to provide '
                        'personalised features.',
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
                        'references, screenshots, photographs, contact details and '
                        'report status.',
                  ),
                  _PrivacySection(
                    title: '8. Guest Use',
                    body:
                        'Guests may use supported public navigation functions '
                        'without creating an account. Guest information should '
                        'remain limited to what is necessary for the permitted feature.',
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
                        'users, administrators and approved service providers where '
                        'necessary.',
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
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 8),
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

class _CampusSubpageHeader extends StatelessWidget {
  const _CampusSubpageHeader({
    required this.subtitle,
    required this.onBack,
    required this.onClose,
  });

  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  splashRadius: 22,
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 23,
                    color: Color(0xFF2A77B4),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Campus',
                              style: TextStyle(color: Color(0xFF38358E)),
                            ),
                            TextSpan(
                              text: 'GO',
                              style: TextStyle(color: Color(0xFFFF0000)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  splashRadius: 22,
                  onPressed: onClose,
                  icon: SvgPicture.asset(AppAssets.closeButton, width: 23),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF115388),
            ),
          ),
        ],
      ),
    );
  }
}
