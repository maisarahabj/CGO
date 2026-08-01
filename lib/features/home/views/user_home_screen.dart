import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/ongoing_class_model.dart';
import '../services/home_service.dart';
import 'home_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({required this.authController, super.key});

  final AuthController authController;

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final HomeService _homeService = HomeService();
  Timer? _refreshTimer;
  OngoingClassModel? _ongoingClass;
  List<OngoingClassModel> _nextClasses = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_refreshSchedule());
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshSchedule()),
    );
  }

  @override
  void didUpdateWidget(covariant UserHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController.profile?.id !=
        widget.authController.profile?.id) {
      unawaited(_refreshSchedule());
    }
  }

  Future<void> _refreshSchedule() async {
    final userId = widget.authController.profile?.id;
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
      debugPrint('Could not load today\'s classes: $error');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      accessMode: HomeAccessMode.registeredUser,
      profile: widget.authController.profile,
      ongoingClass: _ongoingClass,
      nextClasses: _nextClasses,
      onSessionAction: widget.authController.signOut,
    );
  }
}
