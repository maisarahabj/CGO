class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.isRead,
    this.userId,
    this.title,
    this.body,
    this.notificationType,
    this.relatedEntityType,
    this.relatedEntityId,
    this.createdAt,
  });

  final String notificationId;
  final String? userId;
  final String? title;
  final String? body;
  final String? notificationType;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notification_id']?.toString() ?? '',
      userId: _cleanText(map['user_id']),
      title: _cleanText(map['title']),
      body: _cleanText(map['body']),
      notificationType: _cleanText(map['notification_type']),
      relatedEntityType: _cleanText(map['related_entity_type']),
      relatedEntityId: _cleanText(map['related_entity_id']),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title,
      body: body,
      notificationType: notificationType,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get displayTitle {
    final cleaned = title?.trim();

    if (cleaned == null || cleaned.isEmpty) {
      return 'Notification';
    }

    return cleaned;
  }

  String get displayBody {
    return body?.trim() ?? '';
  }

  static String? _cleanText(Object? value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
