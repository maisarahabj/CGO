import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Manages notification loading, unread count,
/// read state and error state.
class NotificationController extends ChangeNotifier {
  NotificationController({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  List<NotificationModel> _notifications = const [];

  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  bool get hasNotifications => _notifications.isNotEmpty;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _notifications = await _notificationService.getCurrentUserNotifications();
    } on PostgrestException catch (error) {
      debugPrint(
        'Notification query failed: '
        '${error.message}',
      );

      _notifications = const [];
      _errorMessage = 'We could not load your notifications.';
    } catch (error, stackTrace) {
      debugPrint('Notification loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _notifications = const [];
      _errorMessage = 'We could not load your notifications.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsRead(NotificationModel notification) async {
    if (notification.isRead) {
      return true;
    }

    _errorMessage = null;

    try {
      await _notificationService.markAsRead(notification.notificationId);

      final index = _notifications.indexWhere(
        (item) => item.notificationId == notification.notificationId,
      );

      if (index != -1) {
        final updated = List<NotificationModel>.from(_notifications);

        updated[index] = notification.copyWith(isRead: true);

        _notifications = updated;
        notifyListeners();
      }

      return true;
    } on PostgrestException catch (error) {
      debugPrint(
        'Notification read update failed: '
        '${error.message}',
      );

      _errorMessage = 'We could not update the notification.';
      notifyListeners();

      return false;
    } catch (error, stackTrace) {
      debugPrint(
        'Notification read update failed: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'We could not update the notification.';
      notifyListeners();

      return false;
    }
  }

  Future<void> refresh() {
    return loadNotifications();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
