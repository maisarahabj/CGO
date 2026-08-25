import 'dart:ui' as ui;

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

  static const Color _headingBlue = Color(0xFF2A77B4);
  static const Color _headingOrange = Color(0xFFF76B00);
  static const Color _bannerInk = Color(0xFF3C5F7B);

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
                  Transform.translate(
                    // Keep the day selector in the same place while the
                    // artwork continues behind the rounded timetable surface.
                    offset: const Offset(0, -70),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
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
      height: 228,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -40,
              right: 0,
              top: -18,
              height: 630,
              child: Image.asset(
                AppAssets.loginBackground,
                fit: BoxFit.cover,
                // Adjust this alignment to reposition the UNIMY artwork.
                alignment: const Alignment(-0.70, -0.42),
              ),
            ),
            ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
            Positioned(
              left: 112,
              right: 2,
              top: 13,
              bottom: 65,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 28.45,
                    sigmaY: 28.45,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(57),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xEBE8EFFF),
                          Color(0xEBFFFFFF),
                          Color(0xEBE8EFFF),
                        ],
                        stops: [0, 0.53, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 132,
              right: 12,
              top: 10,
              bottom: 67,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 35,
                          fontWeight: FontWeight.w700,
                          height: 1.04,
                        ),
                        children: [
                          TextSpan(
                            text: 'Find a ',
                            style: TextStyle(color: _headingBlue),
                          ),
                          TextSpan(
                            text: 'Room',
                            style: TextStyle(color: _headingOrange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Find your classroom and keep track of your '
                    'daily schedule all in one place.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'RobotoCondensed',
                      fontFamilyFallback: ['Roboto'],
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: _bannerInk,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _bannerButton(
                    text: 'VIEW ROOM SCHEDULE',
                    onTap: _openRoomSchedule,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: _bannerInk,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
                letterSpacing: 0.1,
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
