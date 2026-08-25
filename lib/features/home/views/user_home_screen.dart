import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../models/ongoing_class_model.dart';
import '../services/home_service.dart';
import 'home_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({
    required this.authController,
    this.initialDestinationNodeId,
    super.key,
  });

  final AuthController authController;
  final String? initialDestinationNodeId;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final HomeService _homeService = HomeService();
  final NotificationController _notificationController =
      NotificationController();

  Timer? _refreshTimer;

  OngoingClassModel? _ongoingClass;
  List<OngoingClassModel> _nextClasses = const [];

  @override
  void initState() {
    super.initState();

    _notificationController.addListener(_handleNotificationStateChanged);
    widget.authController.addListener(_handleAuthControllerChanged);

    unawaited(_refreshSchedule());
    unawaited(_refreshNotifications());

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_refreshSchedule());
      unawaited(_refreshNotifications());
    });
  }

  @override
  void didUpdateWidget(covariant UserHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.authController != widget.authController) {
      oldWidget.authController.removeListener(_handleAuthControllerChanged);
      widget.authController.addListener(_handleAuthControllerChanged);
    }

    if (oldWidget.authController.profile?.id !=
        widget.authController.profile?.id) {
      unawaited(_refreshSchedule());
      unawaited(_refreshNotifications());
    }
  }

  void _handleAuthControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleNotificationStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshNotifications() async {
    await _notificationController.loadNotifications();
  }

  Future<void> _refreshSchedule() async {
    // my_schedule is written using Supabase Auth's user UUID. Use that same
    // identity source here instead of relying only on the profile row.
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();

    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _ongoingClass = null;
          _nextClasses = const [];
        });
      }
      return;
    }

    try {
      final schedule = await _homeService.loadTodaySchedule(userId: userId);

      if (!mounted) return;

      setState(() {
        _ongoingClass = schedule.ongoingClass;
        _nextClasses = schedule.nextClasses;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load home schedule: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _ongoingClass = null;
          _nextClasses = const [];
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    widget.authController.removeListener(_handleAuthControllerChanged);

    _notificationController
      ..removeListener(_handleNotificationStateChanged)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      accessMode: HomeAccessMode.registeredUser,
      profile: widget.authController.profile,
      ongoingClass: _ongoingClass,
      nextClasses: _nextClasses,
      unreadNotificationCount: _notificationController.unreadCount,
      onNotificationRefresh: _refreshNotifications,
      onScheduleRefresh: _refreshSchedule,
      onProfileRefresh: widget.authController.refreshProfile,
      onSessionAction: widget.authController.signOut,
      initialDestinationNodeId: widget.initialDestinationNodeId,
    );
  }
}
