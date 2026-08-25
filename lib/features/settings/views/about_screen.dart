import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: 'About CampusGO',
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(22, 24, 22, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CampusGO is an indoor campus navigation application '
                      'designed to help students, lecturers, staff and visitors '
                      'find supported destinations around campus.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14.5,
                        height: 1.55,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),

                    SizedBox(height: 26),

                    Text(
                      'Key Features',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF115388),
                      ),
                    ),

                    SizedBox(height: 12),

                    _FeatureItem(
                      icon: Icons.route_outlined,
                      text: 'Indoor navigation and route guidance',
                    ),

                    _FeatureItem(
                      icon: Icons.qr_code_scanner_rounded,
                      text: 'QR-supported starting point selection',
                    ),

                    _FeatureItem(
                      icon: Icons.calendar_month_outlined,
                      text: 'Timetable-assisted navigation',
                    ),

                    _FeatureItem(
                      icon: Icons.meeting_room_outlined,
                      text: 'Room and booking functionality',
                    ),

                    _FeatureItem(
                      icon: Icons.accessible_forward_outlined,
                      text: 'Accessibility-friendly routes',
                    ),

                    _FeatureItem(
                      icon: Icons.notifications_none_rounded,
                      text: 'Notifications and reminders',
                    ),

                    _FeatureItem(
                      icon: Icons.support_agent_outlined,
                      text: 'Issue reporting and support',
                    ),

                    SizedBox(height: 24),

                    Divider(
                      color: Color(0xFFE1E1E1),
                    ),

                    SizedBox(height: 18),

                    Text(
                      'CampusGO is developed as an academic project for UNIMY.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13.5,
                        height: 1.45,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF2A77B4),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.35,
                  color: Color(0xFF3F3F3F),
                ),
              ),
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
                              style: TextStyle(
                                color: Color(0xFF38358E),
                              ),
                            ),
                            TextSpan(
                              text: 'GO',
                              style: TextStyle(
                                color: Color(0xFFFF0000),
                              ),
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
                  icon: SvgPicture.asset(
                    AppAssets.closeButton,
                    width: 23,
                  ),
                ),
              ],
            ),
          ),

          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF115388),
            ),
          ),
        ],
      ),
    );
  }
}