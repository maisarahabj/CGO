import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../features/notifications/widgets/unread_notification_badge.dart';
import '../../features/profile/models/profile_model.dart';

class CampusNavigationDrawer extends StatelessWidget {
  const CampusNavigationDrawer({
    required this.isRegisteredUser,
    required this.isAccessibilityEnabled,
    required this.onNotificationPressed,
    required this.onTimetablePressed,
    required this.onSettingsPressed,
    required this.onAccessibilityChanged,
    required this.onHelpPressed,
    required this.onSessionAction,
    this.unreadNotificationCount = 0,
    this.onProfilePressed,
    this.profile,
    super.key,
  });

  final bool isRegisteredUser;
  final ProfileModel? profile;
  final bool isAccessibilityEnabled;
  final VoidCallback onNotificationPressed;
  final VoidCallback onTimetablePressed;
  final VoidCallback onSettingsPressed;
  final ValueChanged<bool> onAccessibilityChanged;
  final VoidCallback onHelpPressed;
  final Future<void> Function() onSessionAction;
  final int unreadNotificationCount;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = math.min(
      300.0,
      math.max(
        240.0,
        MediaQuery.sizeOf(context).width * 0.69,
      ),
    );

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _CloseDrawerButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            _ProfileHeader(
              isRegisteredUser: isRegisteredUser,
              profile: profile,
              onPressed: onProfilePressed,
            ),
            const _InsetDivider(horizontalMargin: 47),
            const _CampusGoBrand(),
            const _InsetDivider(horizontalMargin: 28),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (isRegisteredUser) ...[
                    _DrawerMenuItem(
                      title: 'Notification',
                      iconAsset: AppAssets.drawerNotification,
                      onTap: onNotificationPressed,
                      trailing: UnreadNotificationBadge(
                        count: unreadNotificationCount,
                      ),
                    ),
                    const _InsetDivider(horizontalMargin: 28),
                  ],
                  _DrawerMenuItem(
                    title: 'Timetable',
                    description: isRegisteredUser
                        ? 'Class schedules\n'
                            'Room availability\n'
                            'Reserve & view bookings'
                        : 'Class schedules\n'
                            'Room availability',
                    iconAsset: AppAssets.drawerTimetable,
                    onTap: onTimetablePressed,
                  ),
                  const _InsetDivider(horizontalMargin: 28),
                  _DrawerMenuItem(
                    title: 'Settings',
                    iconAsset: AppAssets.drawerSettings,
                    onTap: onSettingsPressed,
                    verticalPadding: 17,
                  ),
                  const _InsetDivider(horizontalMargin: 28),
                  _DrawerMenuItem(
                    title: 'Accessibility',
                    description:
                        'Wheelchair accessible\n'
                        'Avoid steps and prefer lifts',
                    iconAsset: AppAssets.drawerAccess,
                    onTap: () {
                      onAccessibilityChanged(
                        !isAccessibilityEnabled,
                      );
                    },
                    trailingBelow: _CompactSwitch(
                      value: isAccessibilityEnabled,
                      onChanged: onAccessibilityChanged,
                    ),
                  ),
                  const _InsetDivider(horizontalMargin: 28),
                  _DrawerMenuItem(
                    title: 'Help & Feedback',
                    iconAsset: AppAssets.helpAndFeedback,
                    onTap: onHelpPressed,
                  ),
                  const _InsetDivider(horizontalMargin: 28),
                ],
              ),
            ),
            _SessionAction(
              label: isRegisteredUser ? 'Log out' : 'Sign in',
              onPressed: () async {
                Navigator.of(context).pop();
                await onSessionAction();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseDrawerButton extends StatelessWidget {
  const _CloseDrawerButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Close menu',
          onPressed: onPressed,
          padding: const EdgeInsets.only(right: 12),
          icon: SvgPicture.asset(
            AppAssets.closeButton,
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isRegisteredUser,
    required this.profile,
    required this.onPressed,
  });

  final bool isRegisteredUser;
  final ProfileModel? profile;
  final VoidCallback? onPressed;

  static String _textOrFallback(
    String? value,
    String fallback,
  ) {
    final cleanedValue = value?.trim();

    if (cleanedValue == null || cleanedValue.isEmpty) {
      return fallback;
    }

    return cleanedValue;
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = isRegisteredUser
        ? _textOrFallback(
            profile?.fullName,
            'CampusGO User',
          )
        : 'Guest';

    final String secondaryText = isRegisteredUser
        ? _textOrFallback(
            profile?.unimyId,
            'Student / Lecturer',
          )
        : 'Public access';

    final String initials =
        isRegisteredUser ? profile?.initials ?? 'U' : 'G';

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        36,
        0,
        12,
        20,
      ),
      child: Row(
        children: [
          _ProfileAvatar(
            initials: initials,
            imageUrl: isRegisteredUser
                ? profile?.profileImageUrl
                : null,
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
                  secondaryText,
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
    );

    if (onPressed == null) {
      return content;
    }

    return Semantics(
      button: true,
      label: 'Edit profile information',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: content,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.initials,
    required this.imageUrl,
  });

  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2A77B4),
              width: 2.2,
            ),
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
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _CampusGoBrand extends StatelessWidget {
  const _CampusGoBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        30,
        22,
        12,
        22,
      ),
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
                    TextSpan(
                      text: 'Campus',
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
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.title,
    required this.iconAsset,
    required this.onTap,
    this.description,
    this.trailing,
    this.trailingBelow,
    this.verticalPadding = 14,
  });

  final String title;
  final String? description;
  final String iconAsset;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? trailingBelow;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            36,
            verticalPadding,
            28,
            verticalPadding,
          ),
          child: Row(
            crossAxisAlignment: description == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 29,
                height: 31,
                child: Align(
                  alignment: Alignment.topCenter,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E1E1E),
                        height: 1.05,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF61727D),
                          height: 1.15,
                        ),
                      ),
                    ],
                    if (trailingBelow != null) ...[
                      const SizedBox(height: 7),
                      trailingBelow!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      label: 'Wheelchair accessible routes',
      child: InkWell(
        onTap: () {
          onChanged(!value);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          width: 26,
          height: 14,
          padding: const EdgeInsets.all(2),
          alignment: value
              ? Alignment.centerRight
              : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF2A77B4)
                : const Color(0xFF8D8D8D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SizedBox(
            width: 10,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionAction extends StatelessWidget {
  const _SessionAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
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
                Text(
                  label,
                  style: const TextStyle(
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
    );
  }
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider({
    required this.horizontalMargin,
  });

  final double horizontalMargin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
      ),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFD0D0D0),
      ),
    );
  }
}