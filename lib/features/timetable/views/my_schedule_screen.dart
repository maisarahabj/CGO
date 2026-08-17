import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/campus_navigation_drawer.dart';
import '../controllers/schedule_controller.dart';
import '../models/timetable_model.dart';
import '../widgets/weekly_timetable_view.dart';
import 'timetable_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final ScheduleController _controller;

  bool _isAccessibilityEnabled = false;

  static const Color _blue = Color(0xFF176F9E);

  @override
  void initState() {
    super.initState();

    _controller = ScheduleController();

    _controller.loadSchedule();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();

    action();
  }

  Future<void> _handleSessionAction() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  Widget _buildDrawer() {
    return CampusNavigationDrawer(
      isRegisteredUser: true,
      profile: null,
      isAccessibilityEnabled: _isAccessibilityEnabled,

      onProfilePressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.editProfile);
        });
      },

      onNotificationPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.notifications);
        });
      },

      onTimetablePressed: () {
        Navigator.of(context).pop();
      },

      onSettingsPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.settings);
        });
      },

      onAccessibilityChanged: (value) {
        setState(() {
          _isAccessibilityEnabled = value;
        });
      },

      onHelpPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.support);
        });
      },

      onSessionAction: _handleSessionAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawerScrimColor: const Color(0x3D000000),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null &&
                _controller.entries.isEmpty) {
              return _errorState();
            }

            return RefreshIndicator(
              onRefresh: _controller.loadSchedule,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _findRoomBanner(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
                    child: WeeklyTimetableView(
                      days: ScheduleController.weekDays,
                      selectedDay: _controller.selectedDay,
                      entries: _controller.selectedDayEntries,
                      currentClass: _controller.currentClass,
                      onDaySelected: _controller.setSelectedDay,
                      onNavigate: _handleNavigate,
                      onRemove: _removeEntry,
                      isBusy: _controller.isBusy,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        tooltip: 'Open menu',
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.black87, size: 27),
      ),
      title: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(
              text: 'Campus',
              style: TextStyle(color: Color(0xFF342C86)),
            ),
            TextSpan(
              text: 'GO',
              style: TextStyle(color: Color(0xFFE31919)),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Close',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.close, color: Colors.black87, size: 27),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _findRoomBanner() {
    return Container(
      height: 155,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/features/auth/login_background.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(145, 17, 14, 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Find a Room',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find your classroom and keep track '
              'of your daily schedule all in one place.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF27333C),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 28,
              child: FilledButton(
                onPressed: _openRoomSchedule,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text(
                  'VIEW ROOM SCHEDULE',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    final message =
        _controller.errorMessage ??
        'Unable to load your schedule. Please try again.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 46),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _controller.loadSchedule,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoomSchedule() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TimetableScreen()))
        .then((_) {
          if (mounted) {
            _controller.loadSchedule();
          }
        });
  }

  Future<void> _removeEntry(TimetableModel entry) async {
    final shouldRemove =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Remove class?'),
              content: Text(
                'Remove ${entry.subjectName ?? 'this class'} '
                'from My Schedule?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldRemove) {
      return;
    }

    final removed = await _controller.removeEntry(entry.timetableId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            removed
                ? 'Removed from My Schedule.'
                : 'Unable to remove this class.',
          ),
        ),
      );
  }

  void _handleNavigate(TimetableModel entry) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Navigation to ${entry.roomName ?? 'this room'} '
            'will connect to the navigation feature.',
          ),
        ),
      );
  }
}
