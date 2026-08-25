import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
 
import '../../../core/constants/app_assets.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../widgets/unread_notification_badge.dart';
 
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
 
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}
 
class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController _controller;
 
  @override
  void initState() {
    super.initState();
    _controller = NotificationController();
    unawaited(_controller.loadNotifications());
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  Future<void> _openNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      final success = await _controller.markAsRead(notification);
 
      if (!success && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _controller.errorMessage ??
                    'Unable to update the notification.',
              ),
            ),
          );
      }
    }
 
    if (!mounted) {
      return;
    }
 
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailsSheet(
        notification: notification,
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
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
          SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF115388),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  child: UnreadNotificationBadge(
                    count: _controller.unreadCount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildBody() {
    if (_controller.isLoading && !_controller.hasNotifications) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2A77B4),
        ),
      );
    }
 
    if (_controller.errorMessage != null && !_controller.hasNotifications) {
      return _ErrorState(
        message: _controller.errorMessage!,
        onRetry: _controller.loadNotifications,
      );
    }
 
    if (!_controller.hasNotifications) {
      return RefreshIndicator(
        onRefresh: _controller.loadNotifications,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyNotificationState(),
            ),
          ],
        ),
      );
    }
 
    final notifications = _controller.notifications;
 
    return RefreshIndicator(
      onRefresh: _controller.loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
 
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == notifications.length - 1 ? 0 : 10,
            ),
            child: NotificationTile(
              notification: notification,
              onTap: () {
                unawaited(_openNotification(notification));
              },
            ),
          );
        },
      ),
    );
  }
}
 
class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({
    required this.notification,
  });
 
  final NotificationModel notification;
 
  @override
  Widget build(BuildContext context) {
    final type = notification.notificationType?.trim();
 
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3D3D3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF2A77B4),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      notification.displayTitle,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF115388),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                notification.displayBody.isEmpty
                    ? 'No additional information is available.'
                    : notification.displayBody,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              if (type != null && type.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Type: $type',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF38358E),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
 
class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: Color(0xFF2A77B4),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF115388),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you receive CampusGO notifications, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });
 
  final String message;
  final Future<void> Function() onRetry;
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                unawaited(onRetry());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38358E),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
