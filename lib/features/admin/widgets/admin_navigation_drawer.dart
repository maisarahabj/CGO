import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../profile/models/profile_model.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({
    required this.onProfilePressed,
    required this.onDashboardPressed,
    required this.onMapManagementPressed,
    required this.onSettingsPressed,
    required this.onPrivacyLegalPressed,
    required this.onLogoutPressed,
    this.profile,
    super.key,
  });

  final ProfileModel? profile;
  final VoidCallback onProfilePressed;
  final VoidCallback onDashboardPressed;
  final VoidCallback onMapManagementPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onPrivacyLegalPressed;
  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = math.min(
      300.0,
      math.max(240.0, MediaQuery.sizeOf(context).width * 0.69),
    );

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close menu',
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.only(right: 12),
                  icon: SvgPicture.asset(
                    AppAssets.closeButton,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
            _AdminProfileHeader(profile: profile, onPressed: onProfilePressed),
            const _AdminDivider(horizontalMargin: 47),
            const _AdminBrand(),
            const _AdminDivider(horizontalMargin: 28),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _AdminMenuItem(
                    title: 'Dashboard',
                    iconAsset: AppAssets.drawerDashboard,
                    onTap: onDashboardPressed,
                  ),
                  const _AdminDivider(horizontalMargin: 28),
                  _AdminMenuItem(
                    title: 'Map Management',
                    iconAsset: AppAssets.drawerMap,
                    onTap: onMapManagementPressed,
                  ),
                  const _AdminDivider(horizontalMargin: 28),
                  _AdminMenuItem(
                    title: 'Settings',
                    iconAsset: AppAssets.drawerSettings,
                    onTap: onSettingsPressed,
                  ),
                  const _AdminDivider(horizontalMargin: 28),
                  _AdminMenuItem(
                    title: 'Privacy & Legal',
                    iconAsset: AppAssets.helpAndFeedback,
                    onTap: onPrivacyLegalPressed,
                  ),
                  const _AdminDivider(horizontalMargin: 28),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await onLogoutPressed();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppAssets.logout,
                          width: 25,
                          height: 25,
                        ),
                        const SizedBox(width: 13),
                        const Text(
                          'Log out',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2A77B4),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileHeader extends StatelessWidget {
  const _AdminProfileHeader({required this.profile, required this.onPressed});

  final ProfileModel? profile;
  final VoidCallback onPressed;

  static String _textOrFallback(String? value, String fallback) {
    final cleanedValue = value?.trim();
    return cleanedValue == null || cleanedValue.isEmpty
        ? fallback
        : cleanedValue;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _textOrFallback(profile?.fullName, 'CampusGO Admin');
    final adminId = _textOrFallback(profile?.unimyId, 'Administrator');
    final initials = profile?.initials ?? 'A';

    return Semantics(
      button: true,
      label: 'Edit profile information',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 12, 20),
            child: Row(
              children: [
                _AdminAvatar(
                  initials: initials,
                  imageUrl: profile?.profileImageUrl,
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        adminId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF61727D),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.initials, required this.imageUrl});

  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E1E1E), width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: SvgPicture.asset(
              AppAssets.profileCamera,
              width: 24,
              height: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 22, 12, 22),
      child: Row(
        children: [
          Image.asset(
            AppAssets.campusGoLocationPin,
            width: 27,
            height: 45,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38358E),
                    height: 1,
                  ),
                  children: [
                    TextSpan(text: 'Campus'),
                    TextSpan(
                      text: 'GO',
                      style: TextStyle(color: Color(0xFFFF0000)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  const _AdminMenuItem({
    required this.title,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 17, 13, 17),
          child: Row(
            children: [
              SizedBox(
                width: 29,
                height: 31,
                child: Center(
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 27,
                    height: 29,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E1E),
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDivider extends StatelessWidget {
  const _AdminDivider({required this.horizontalMargin});

  final double horizontalMargin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFD0D0D0)),
    );
  }
}
