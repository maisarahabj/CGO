import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/models/profile_model.dart';
import '../widgets/admin_current_map.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/admin_stat_card.dart';

/// Role-specific starting screen for an authenticated administrator.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    required this.authController,
    this.mapContent,
    super.key,
  });

  final AuthController authController;

  /// Optional test or platform-specific replacement for the dashboard map.
  final Widget? mapContent;

  void _openFromDrawer(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _signOut(BuildContext context) async {
    await authController.signOut();
    if (!context.mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = authController.profile;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        drawerScrimColor: const Color(0x3D000000),
        drawer: AdminNavigationDrawer(
          profile: profile,
          onProfilePressed: () {
            _openFromDrawer(context, AppRoutes.editProfile);
          },
          onDashboardPressed: () => Navigator.of(context).pop(),
          onMapManagementPressed: () {
            _openFromDrawer(context, AppRoutes.adminMapManagement);
          },
          onSettingsPressed: () {
            _openFromDrawer(context, AppRoutes.settings);
          },
          onPrivacyLegalPressed: () {
            _openFromDrawer(context, AppRoutes.adminPrivacyLegal);
          },
          onLogoutPressed: () => _signOut(context),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Builder(
                builder: (scaffoldContext) {
                  return _AdminTopBar(
                    profile: profile,
                    onMenuPressed: () =>
                        Scaffold.of(scaffoldContext).openDrawer(),
                    onNotificationsPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminNotifications);
                    },
                  );
                },
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TasksPanel(
                                onBookingRequestsPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminBookingRequests);
                                },
                                onOpenReportsPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminIssueReports);
                                },
                                onClosedRoutesPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminRouteManagement);
                                },
                                onOpenTicketsPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminIssueReports);
                                },
                              ),
                              const SizedBox(height: 24),
                              _CurrentMapSection(
                                mapContent: mapContent,
                                onManageMapPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminMapManagement);
                                },
                              ),
                              const SizedBox(height: 18),
                              _AdminActionButton(
                                label: 'Booking Requests',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminBookingRequests);
                                },
                              ),
                              _AdminActionButton(
                                label: 'Rooms & Availability',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminRoomAvailability);
                                },
                              ),
                              _AdminActionButton(
                                label: 'Route Management',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminRouteManagement);
                                },
                              ),
                              _AdminActionButton(
                                label: 'Issue Report',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminIssueReports);
                                },
                              ),
                              _AdminActionButton(
                                label: 'FAQ Management',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminFaq);
                                },
                              ),
                              _AdminActionButton(
                                label: 'QR Checkpoints',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminQrCheckpoints);
                                },
                              ),
                              _AdminActionButton(
                                label: 'Privacy & Legal',
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.adminPrivacyLegal);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.profile,
    required this.onMenuPressed,
    required this.onNotificationsPressed,
  });

  final ProfileModel? profile;
  final VoidCallback onMenuPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            InkWell(
              onTap: onMenuPressed,
              customBorder: const CircleBorder(),
              child: _TopBarAvatar(profile: profile),
            ),
            IconButton(
              tooltip: 'Open menu',
              onPressed: onMenuPressed,
              icon: SvgPicture.asset(
                AppAssets.hamburger,
                width: 30,
                height: 24,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Admin notifications',
              onPressed: onNotificationsPressed,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    AppAssets.drawerNotification,
                    width: 28,
                    height: 30,
                  ),
                  Positioned(
                    top: -8,
                    right: -11,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 20,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3F46),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '13',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
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

class _TopBarAvatar extends StatelessWidget {
  const _TopBarAvatar({required this.profile});

  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile?.profileImageUrl;
    final initials = profile?.initials ?? 'A';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A77B4), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TasksPanel extends StatelessWidget {
  const _TasksPanel({
    required this.onBookingRequestsPressed,
    required this.onOpenReportsPressed,
    required this.onClosedRoutesPressed,
    required this.onOpenTicketsPressed,
  });

  final VoidCallback onBookingRequestsPressed;
  final VoidCallback onOpenReportsPressed;
  final VoidCallback onClosedRoutesPressed;
  final VoidCallback onOpenTicketsPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
            AdminStatCard(
              label: 'Pending Booking requests',
              count: 1,
              onPressed: onBookingRequestsPressed,
            ),
            AdminStatCard(
              label: 'Open reports',
              count: 1,
              onPressed: onOpenReportsPressed,
            ),
            AdminStatCard(
              label: 'Closed routes',
              count: 1,
              onPressed: onClosedRoutesPressed,
            ),
            AdminStatCard(
              label: 'Open tickets',
              count: 1,
              onPressed: onOpenTicketsPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentMapSection extends StatelessWidget {
  const _CurrentMapSection({
    required this.mapContent,
    required this.onManageMapPressed,
  });

  final Widget? mapContent;
  final VoidCallback onManageMapPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Current Map',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onManageMapPressed,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Manage Map',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF868DA6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        AppAssets.moreRightArrow,
                        width: 9,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          key: const Key('admin-spline-map-slot'),
          height: 260,
          width: double.infinity,
          child: mapContent ?? const AdminCurrentMap(),
        ),
      ],
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                      AppAssets.moreRightArrow,
                      width: 9,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
