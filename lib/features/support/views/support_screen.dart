import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
 
import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import 'faq_screen.dart';
 
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: 'Help & Feedback',
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
                children: [
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF115388),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find answers to common questions or report a problem.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF68727D),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SupportTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Frequently Asked Questions',
                    subtitle: 'Browse common CampusGO questions and answers.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FaqScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _SupportTile(
                    icon: Icons.report_problem_outlined,
                    title: 'Report an Issue',
                    subtitle:
                        'Tell us about navigation, room, QR code or application issues.',
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.issueReport,
                      );
                    },
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
 
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF9DC7DD),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: const Color(0xFF2A77B4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF303030),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        height: 1.35,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF2A77B4),
                size: 24,
              ),
            ],
          ),
        ),
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
