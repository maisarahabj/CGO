import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _stepByStepEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                children: [
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About CampusGO',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.aboutCampusGo,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Notifications & Alerts'),
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification',
                        subtitle: 'Class reminders and CampusGO updates',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF2A77B4),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFB7B7B7),
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.directions_walk_outlined,
                        title: 'Step by Step Cues',
                        subtitle: 'Show navigation guidance cues',
                        trailing: Switch(
                          value: _stepByStepEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF2A77B4),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFB7B7B7),
                          onChanged: (value) {
                            setState(() {
                              _stepByStepEnabled = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Account'),
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account and login',
                        subtitle: 'UNIMY account information',
                        onTap: _showAccountInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Activity'),
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.history_rounded,
                        title: 'Navigation history',
                        onTap: _showNavigationHistoryInfo,
                      ),
                      _SettingsTile(
                        icon: Icons.calendar_month_outlined,
                        title: 'Bookings',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.bookings,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Help & Feedback'),
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Feedback',
                        subtitle: 'FAQ and report an issue',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.support,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Privacy & Legal'),
                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'CampusGO Privacy Policy',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.privacyPolicy,
                          );
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'CampusGO Terms of Use',
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.termsOfUse,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  tooltip: 'Menu',
                  splashRadius: 22,
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: SvgPicture.asset(
                    AppAssets.hamburger,
                    width: 27,
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
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: SvgPicture.asset(
                    AppAssets.closeButton,
                    width: 23,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(
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

  void _showAccountInfo() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Account and Login',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              color: Color(0xFF115388),
            ),
          ),
          content: const Text(
            'CampusGO account access is managed through your UNIMY '
            'authentication credentials. Profile information can be viewed '
            'from the Profile option in the main menu.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNavigationHistoryInfo() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Navigation History',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              color: Color(0xFF115388),
            ),
          ),
          content: const Text(
            'Navigation history will contain previously completed CampusGO '
            'routes where history tracking is available.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2A77B4),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF9DC7DD),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(
          children.length,
          (index) {
            return Column(
              children: [
                children[index],
                if (index != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 54,
                    endIndent: 14,
                    color: Color(0xFFE1E6E9),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(
                  icon,
                  size: 21,
                  color: const Color(0xFF303030),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF303030),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11.5,
                          height: 1.3,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFF8295A3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}