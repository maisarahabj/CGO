import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../widgets/notification_tile.dart';
import '../widgets/unread_notification_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  late final NotificationController
      _notificationController;

  @override
  void initState() {
    super.initState();

    _notificationController =
        NotificationController();

    unawaited(
      _notificationController.loadNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  Future<void> _openNotification(
    NotificationModel notification,
  ) async {
    if (!notification.isRead) {
      final didUpdate =
          await _notificationController.markAsRead(
        notification,
      );

      if (!didUpdate && mounted) {
        _showMessage(
          _notificationController.errorMessage ??
              'Notification could not be updated.',
          isError: true,
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
      builder: (context) {
        return _NotificationDetailsSheet(
          notification: notification,
        );
      },
    );
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF276749),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notificationController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor:
              const Color(0xFFF7F9FB),

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            foregroundColor:
                const Color(0xFF303030),

            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            title: const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF38358E),
              ),
            ),

            centerTitle: true,

            actions: [
              Padding(
                padding:
                    const EdgeInsets.only(right: 16),
                child: Center(
                  child: UnreadNotificationBadge(
                    count:
                        _notificationController
                            .unreadCount,
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
    if (_notificationController.isLoading &&
        !_notificationController
            .hasNotifications) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notificationController.errorMessage !=
            null &&
        !_notificationController
            .hasNotifications) {
      return _ErrorState(
        message:
            _notificationController.errorMessage!,
        onRetry:
            _notificationController
                .loadNotifications,
      );
    }

    if (!_notificationController
        .hasNotifications) {
      return RefreshIndicator(
        onRefresh:
            _notificationController
                .loadNotifications,
        child: const CustomScrollView(
          physics:
              AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyNotificationState(),
            ),
          ],
        ),
      );
    }

    final notifications =
        _notificationController.notifications;

    return RefreshIndicator(
      onRefresh:
          _notificationController
              .loadNotifications,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
        ),
        itemCount: notifications.length,
        separatorBuilder:
            (context, index) {
          return const Divider(
            height: 1,
            thickness: 1,
            indent: 80,
            color: Color(0xFFE7E7E7),
          );
        },
        itemBuilder: (context, index) {
          final notification =
              notifications[index];

          return NotificationTile(
            notification: notification,
            onTap: () {
              _openNotification(
                notification,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationDetailsSheet
    extends StatelessWidget {
  const _NotificationDetailsSheet({
    required this.notification,
  });

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          24,
          14,
          24,
          32,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFD2D2D2),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 26),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFFE7F3FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color:
                        Color(0xFF2A77B4),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    notification.displayTitle,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF252525),
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

            if (notification.notificationType !=
                null) ...[
              const SizedBox(height: 24),

              Text(
                'Type: ${notification.notificationType}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color:
                      Color(0xFF858585),
                ),
              ),
            ],

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF38358E),
                  shape:
                      const StadiumBorder(),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
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

class _EmptyNotificationState
    extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFEAF4FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .notifications_none_rounded,
                size: 44,
                color:
                    Color(0xFF2A77B4),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'No notifications yet',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF38358E),
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
                color:
                    Color(0xFF777777),
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
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color:
                  Color(0xFFB3261E),
            ),

            const SizedBox(height: 16),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color:
                    Color(0xFF555555),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton(
              onPressed: () {
                onRetry();
              },
              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}