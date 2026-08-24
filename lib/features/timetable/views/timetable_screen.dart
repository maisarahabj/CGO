import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/campus_navigation_drawer.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/timetable_controller.dart';
import '../models/timetable_model.dart';
import '../widgets/timetable_entry_card.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    this.guestMode = false,
    this.initialRoomName,
  });

  final bool guestMode;
  final String? initialRoomName;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final TimetableController _controller;
  late final ScheduleController _scheduleController;
  late final TextEditingController _searchController;

  bool _isAccessibilityEnabled = false;

  static const Color _blue = Color(0xFF176F9E);
  static const Color _green = Color(0xFF78C66A);
  static const Color _lightGreen = Color(0xFFEDF8EC);

  @override
  void initState() {
    super.initState();

    _controller = TimetableController();
    _scheduleController = ScheduleController();
    _searchController = TextEditingController();

    _load();

    if (!widget.guestMode) {
      _scheduleController.loadSchedule();
    }
  }

  Future<void> _load() async {
    await _controller.loadTimetable();

    if (!mounted) return;

    final initialRoom = widget.initialRoomName?.trim();

    if (initialRoom != null &&
        initialRoom.isNotEmpty &&
        _controller.availableRooms.any(
          (room) => room.toLowerCase() == initialRoom.toLowerCase(),
        )) {
      _controller.selectRoom(initialRoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scheduleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Future<void> _handleSessionAction() async {
    try {
      if (!widget.guestMode) {
        await Supabase.instance.client.auth.signOut();
      }

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to complete the session action. '
            'Please try again.',
          ),
        ),
      );
    }
  }

  Widget _buildDrawer() {
    return CampusNavigationDrawer(
      isRegisteredUser: !widget.guestMode,

      // The real ProfileModel is currently supplied to HomeScreen
      // through the shared auth/router layer. We avoid modifying that
      // shared code here, so the drawer uses its built-in fallback.
      profile: null,

      onProfilePressed: widget.guestMode
          ? null
          : () {
              _closeDrawerThen(() {
                Navigator.of(context).pushNamed(AppRoutes.editProfile);
              });
            },

      isAccessibilityEnabled: _isAccessibilityEnabled,

      onNotificationPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.notifications);
        });
      },

      // Timetable is already open, so simply close the drawer.
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
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null) {
              return _errorState();
            }

            return Column(
              children: [
                _buildBanner(),
                _buildRoomSearch(),
                _buildDaySelector(),
                Expanded(child: _buildRoomSchedule()),
              ],
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
          FocusScope.of(context).unfocus();
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

  Widget _buildBanner() {
    return SizedBox(
      height: 145,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: -32,
            height: 180,
            child: Image.asset(
              AppAssets.loginBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.40)),
          Padding(
            padding: const EdgeInsets.fromLTRB(145, 10, 14, 20),
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
                  'View real-time room schedules to check '
                  'empty or occupied slots.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202A31),
                  ),
                ),
                if (!widget.guestMode) ...[
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.center,
                    child: _gradientBannerButton(
                      text: 'YOUR BOOKINGS',
                      onTap: _openBookings,
                    ),
                  ),
                ],
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

  Widget _buildRoomSearch() {
    final results = _controller.searchResults;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        children: [
          SizedBox(
            height: 55,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _controller.setSearchQuery(value);
              },
              style: const TextStyle(fontFamily: 'Raleway', fontSize: 16),
              decoration: InputDecoration(
                hintText:
                    _controller.selectedRoomName ?? 'Search room or class',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(15),
                  child: SvgPicture.asset(
                    AppAssets.destinationPin,
                    width: 24,
                    height: 24,
                  ),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                        icon: SvgPicture.asset(
                          AppAssets.closeButton,
                          width: 16,
                          height: 16,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _blue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: _blue, width: 2),
                ),
              ),
            ),
          ),
          if (_controller.searchQuery.isNotEmpty && results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8E2E9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final entry = results[index];

                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        AppAssets.destinationClassroom,
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      entry.roomName ?? 'Room',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      entry.subjectName ?? entry.subjectCode ?? '',
                    ),
                    onTap: () {
                      _controller.selectSearchResult(entry);

                      _searchController.clear();
                      _controller.setSearchQuery('');

                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          if (_controller.searchQuery.isNotEmpty && results.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8E2E9)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    color: Color(0xFF68727D),
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No matching rooms or classes found.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: Color(0xFF68727D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 54,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: TimetableController.weekDays.map((day) {
          final selected = day == _controller.selectedDay;

          return Expanded(
            child: InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();

                _controller.setDayFilter(day);
              },
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortDay(day),
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 30 : 0,
                    height: 2,
                    decoration: const BoxDecoration(color: _blue),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoomSchedule() {
    final room = _controller.selectedRoomName;

    if (room == null || room.trim().isEmpty) {
      return const Center(
        child: Text(
          'No rooms were found.',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
      );
    }

    final slots = _controller.availabilitySlots;

    return RefreshIndicator(
      onRefresh: _controller.loadTimetable,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$room Daily Timetable',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _navigateToRoom,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _blue),
                    minimumSize: const Size(120, 30),
                  ),
                  icon: SvgPicture.asset(
                    AppAssets.navPointer,
                    width: 13,
                    height: 13,
                  ),
                  label: const Text(
                    'Navigate Now',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 10,
                      color: _blue,
                    ),
                  ),
                ),
                if (!widget.guestMode) ...[
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _bookRoom,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      minimumSize: const Size(120, 30),
                    ),
                    child: const Text(
                      'Book Room',
                      style: TextStyle(fontFamily: 'Raleway', fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 15),
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No timetable information is available '
                  'for this room and day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF777777),
                  ),
                ),
              )
            else
              ...slots.map(_availabilityRow),
          ],
        ),
      ),
    );
  }

  Widget _availabilityRow(RoomAvailabilitySlot slot) {
    final entry = slot.entry;

    return Padding(
      key: ValueKey(
        '${_controller.selectedRoomName}-'
        '${_controller.selectedDay}-'
        '${slot.startMinutes}-'
        '${slot.endMinutes}-'
        '${entry?.timetableId ?? 'available'}',
      ),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, right: 8),
              child: Text(
                slot.timeLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: Color(0xFF555A60),
                ),
              ),
            ),
          ),
          Expanded(
            child: entry == null
                ? _availableCard()
                : TimetableEntryCard(
                    key: ValueKey('class-${entry.timetableId}'),
                    entry: entry,
                    isOngoing: _controller.isEntryOngoing(entry),
                    showLecturer: !widget.guestMode,
                    onTap: () {
                      _showClassDetails(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _availableCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _green),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: const BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Available',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E6D5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    final message =
        _controller.errorMessage ?? 'Something went wrong. Please try again.';

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
              onPressed: _controller.loadTimetable,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDetails(TimetableModel entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subjectName ?? 'Class Details',
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _detail('Code', entry.subjectCode),
                  _detail('Room', entry.roomName),
                  _detail('Day', entry.day),
                  _detail(
                    'Time',
                    '${_formatTime(entry.startTime)}'
                        ' - '
                        '${_formatTime(entry.endTime)}',
                  ),
                  if (!widget.guestMode) _detail('Lecturer', entry.lecturer),
                  if (!widget.guestMode) ...[
                    const SizedBox(height: 14),
                    ListenableBuilder(
                      listenable: _scheduleController,
                      builder: (buttonContext, _) {
                        final saved = _scheduleController.isSaved(
                          entry.timetableId,
                        );

                        final busy = _scheduleController.isBusy(
                          entry.timetableId,
                        );

                        if (_scheduleController.isLoading &&
                            _scheduleController.entries.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: saved
                              ? OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          final removed =
                                              await _scheduleController
                                                  .removeEntry(
                                                    entry.timetableId,
                                                  );

                                          if (!buttonContext.mounted) {
                                            return;
                                          }

                                          ScaffoldMessenger.of(buttonContext)
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
                                        },
                                  icon: const Icon(
                                    Icons.bookmark_remove_outlined,
                                  ),
                                  label: const Text('Remove from My Schedule'),
                                )
                              : FilledButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          final result =
                                              await _scheduleController
                                                  .saveEntry(entry.timetableId);

                                          if (!buttonContext.mounted) {
                                            return;
                                          }

                                          final message = switch (result) {
                                            SaveScheduleResult.added =>
                                              'Added to My Schedule.',
                                            SaveScheduleResult.alreadySaved =>
                                              'This class is already in My Schedule.',
                                            SaveScheduleResult.failed =>
                                              'Unable to add this class.',
                                          };

                                          ScaffoldMessenger.of(buttonContext)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(content: Text(message)),
                                            );
                                        },
                                  icon: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.bookmark_add_outlined),
                                  label: const Text('Add to My Schedule'),
                                ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, String? value) {
    final displayValue = value?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue.isEmpty ? 'Not available' : displayValue,
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRoom() {
    final selectedRoom = _controller.selectedRoomName?.trim();

    if (selectedRoom == null || selectedRoom.isEmpty) {
      return;
    }

    String? nodeId;

    for (final entry in _controller.entries) {
      final roomName = entry.roomName?.trim();

      final candidateNodeId = entry.roomNodeId?.trim();

      if (roomName != null &&
          roomName.toLowerCase() == selectedRoom.toLowerCase() &&
          candidateNodeId != null &&
          candidateNodeId.isNotEmpty) {
        nodeId = candidateNodeId;
        break;
      }
    }

    if (nodeId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Navigation is not available for this room.'),
          ),
        );

      return;
    }

    if (widget.guestMode) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Guest navigation connection is being finalised.'),
          ),
        );

      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.userHome, arguments: nodeId);
  }

  void _bookRoom() {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.bookings, arguments: _controller.selectedRoomName);
  }

  void _openBookings() {
    Navigator.of(context).pushNamed(AppRoutes.bookings);
  }

  String _shortDay(String day) {
    switch (day) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      default:
        return day;
    }
  }

  String _formatTime(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '--:--';
    }

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return text;
  }
}
