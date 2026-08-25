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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF1F8FC) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFB7D9EA)
                  : const Color(0xFFE3E7EA),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFFE0F1FA)
                      : const Color(0xFFF1F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.notificationType),
                  color: const Color(0xFF2A77B4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 16,
                              height: 1.2,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: const Color(0xFF303030),
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 10),
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: SizedBox(
                              width: 8,
                              height: 8,
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
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF969696),
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
