import 'dart:async';

import 'package:flutter/material.dart';

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
                _controller.errorMessage ?? 'Unable to update notification.',
              ),
            ),
          );
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NotificationDetailsSheet(notification: notification);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),

          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,

            leading: IconButton(
              tooltip: 'Back',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1E1E1E),
              ),
            ),

            title: const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38358E),
              ),
            ),

            centerTitle: true,

            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  child: UnreadNotificationBadge(
                    count: _controller.unreadCount,
                  ),
                ),
              ),
            ],
          ),

          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && !_controller.hasNotifications) {
      return const Center(child: CircularProgressIndicator());
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
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: notifications.length,
        separatorBuilder: (_, __) {
          return const Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            color: Color(0xFFE7E7E7),
          );
        },
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return NotificationTile(
            notification: notification,
            onTap: () {
              _openNotification(notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2D2D2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F3FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF2A77B4),
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
                      color: Color(0xFF252525),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              notification.displayBody.isEmpty
                  ? 'No additional information is available.'
                  : notification.displayBody,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B4B4B),
              ),
            ),

            if (notification.notificationType != null) ...[
              const SizedBox(height: 22),
              Text(
                'Type: ${notification.notificationType}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: Color(0xFF858585),
                ),
              ),
            ],

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF38358E),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
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
                color: Color(0xFFEAF4FA),
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
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38358E),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'When you receive CampusGO notifications, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                height: 1.4,
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
  const _ErrorState({required this.message, required this.onRetry});

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
              size: 52,
              color: Color(0xFFB3261E),
            ),

            const SizedBox(height: 16),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
