import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
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
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        tooltip: 'Open menu',
        splashRadius: 22,
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        icon: SvgPicture.asset(AppAssets.hamburger, width: 27),
      ),
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            children: [
              TextSpan(
                text: 'Campus',
                style: TextStyle(color: Color(0xFF38358E)),
              ),
              TextSpan(
                text: 'GO',
                style: TextStyle(color: Color(0xFFFF0000)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Close',
          splashRadius: 22,
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: SvgPicture.asset(AppAssets.closeButton, width: 23),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _findRoomBanner() {
    return SizedBox(
      height: 155,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -32,
            height: 190,
            child: Image.asset(
              AppAssets.loginBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.40)),
          Padding(
            padding: const EdgeInsets.fromLTRB(145, 10, 14, 22),
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
                _gradientBannerButton(
                  text: 'VIEW ROOM SCHEDULE',
                  onTap: _openRoomSchedule,
                  horizontalPadding: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBannerButton({
    required String text,
    required VoidCallback onTap,
    double horizontalPadding = 12,
  }) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF3235BD), Color(0xFF7D2C87), Color(0xFFFF2A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
    final nodeId = entry.roomNodeId?.trim();

    if (nodeId == null || nodeId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Navigation is not available for this room.'),
          ),
        );

      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.userHome, arguments: nodeId);
  }
}
