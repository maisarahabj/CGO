import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';

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
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                children: [
                  _buildIntro(),

                  const SizedBox(height: 18),

                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.aboutCampusGo);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  _SectionLabel('Notifications & Alerts'),

                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification',
                        subtitle: 'Class reminders and news',
                        trailing: Switch(
                          value: _notificationsEnabled,
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
                        trailing: Switch(
                          value: _stepByStepEnabled,
                          onChanged: (value) {
                            setState(() {
                              _stepByStepEnabled = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  _SectionLabel('Account'),

                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account and login',
                        onTap: _showAccountInfo,
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.privacyPolicy);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  _SectionLabel('Activity'),

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
                          Navigator.of(context).pushNamed(AppRoutes.timetable);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  _SectionLabel('Help and Feedback'),

                  _SettingsSection(
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'FAQ',
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.support);
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.report_outlined,
                        title: 'Report an issue',
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.support);
                        },
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'CampusGO Terms of Use',
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.termsOfUse);
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
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF2A77B4),
                  size: 22,
                ),
              ),

              const Expanded(
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: 'Campus',
                          style: TextStyle(color: Color(0xFF38358E)),
                        ),
                        TextSpan(
                          text: 'GO',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Close',
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 27,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),

          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF005B96),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.settings_outlined, size: 42, color: Color(0xFF2A77B4)),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A77B4),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Manage your preferences, privacy, support and app information.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    height: 1.3,
                    color: Color(0xFF61727D),
                  ),
                ),
              ],
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
          title: const Text('Account and Login'),
          content: const Text(
            'CampusGO account access is managed through your UNIMY '
            'authentication credentials. Your profile information can be '
            'viewed from the Profile option in the main menu.',
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
          title: const Text('Navigation History'),
          content: const Text(
            'Navigation history will contain previously completed '
            'CampusGO routes where history tracking is available.',
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
      padding: const EdgeInsets.only(left: 12, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2A77B4),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2A77B4), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],

              if (index != children.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 48,
                  endIndent: 12,
                  color: Color(0xFFD7DDE2),
                ),
            ],
          );
        }),
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
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Icon(icon, size: 20, color: const Color(0xFF303030)),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF303030),
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: Color(0xFF909090),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Color(0xFF8295A3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
