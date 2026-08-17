import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

/// Handles Supabase operations for CampusGO notifications.
class NotificationService {
  NotificationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  /// Loads notifications belonging only to the
  /// currently authenticated user.
  Future<List<NotificationModel>> getCurrentUserNotifications() async {
    final userId = currentUserId;

    if (userId == null) {
      return const [];
    }

    final data = await _client
        .from('notification')
        .select(
          'notification_id, '
          'user_id, '
          'title, '
          'body, '
          'notification_type, '
          'related_entity_type, '
          'related_entity_id, '
          'is_read, '
          'created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromMap)
        .toList();
  }

  /// Marks one notification belonging to the
  /// authenticated user as read.
  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;

    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    await _client
        .from('notification')
        .update({'is_read': true})
        .eq('notification_id', notificationId)
        .eq('user_id', userId);
  }
}
