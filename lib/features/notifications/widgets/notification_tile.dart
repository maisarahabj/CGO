import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? const Color(0xFFF2F8FC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFFE2F1FA)
                      : const Color(0xFFF1F1F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.notificationType),
                  color: const Color(0xFF2A77B4),
                  size: 25,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.displayTitle,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 17,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF242424),
                            ),
                          ),
                        ),

                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: 9,
                              height: 9,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A77B4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (notification.displayBody.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.displayBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          height: 1.35,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Color(0xFF929292),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type?.trim().toLowerCase()) {
      case 'booking':
        return Icons.event_available_outlined;
      case 'timetable':
      case 'class':
        return Icons.calendar_month_outlined;
      case 'navigation':
      case 'map':
        return Icons.location_on_outlined;
      case 'alert':
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day-$month-${local.year}  $hour:$minute';
  }
}
