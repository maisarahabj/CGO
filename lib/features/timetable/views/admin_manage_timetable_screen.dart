import 'package:flutter/material.dart';

import '../controllers/admin_timetable_controller.dart';
import '../models/timetable_model.dart';

class AdminManageTimetableScreen extends StatefulWidget {
  const AdminManageTimetableScreen({super.key});

  @override
  State<AdminManageTimetableScreen> createState() =>
      _AdminManageTimetableScreenState();
}

class _AdminManageTimetableScreenState
    extends State<AdminManageTimetableScreen> {
  late final AdminTimetableController _controller;

  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  static const Color _blue = Color(0xFF176F9E);
  static const Color _darkBlue = Color(0xFF342C86);
  static const Color _green = Color(0xFF78C66A);
  static const Color _lightGreen = Color(0xFFEDF8EC);

  @override
  void initState() {
    super.initState();

    _controller = AdminTimetableController();
    _controller.loadEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _controller.loadEntries,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                if (_controller.isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),

                _buildIntro(),

                const SizedBox(height: 18),

                _buildRoomDaySelector(),

                const SizedBox(height: 18),

                _buildAvailabilitySection(),

                const SizedBox(height: 22),

                _buildManagementHeader(),

                const SizedBox(height: 12),

                _buildSearch(),

                if (_controller.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  _buildErrorBanner(),
                ],

                const SizedBox(height: 14),

                if (_filteredEntries.isEmpty)
                  _buildEmptyState()
                else
                  ..._filteredEntries.map(_entryCard),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 82,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () {
          Navigator.of(context).maybePop();
        },
        icon: const Icon(Icons.arrow_back_ios_new, color: _blue, size: 24),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: 'Campus',
                  style: TextStyle(color: _darkBlue),
                ),
                TextSpan(
                  text: 'GO',
                  style: TextStyle(color: Color(0xFFE31919)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Rooms & Availability',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
        ],
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

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB6D4E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timetable & Availability Data',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage class schedules and '
            'review how timetable changes '
            'affect room availability.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Color(0xFF68727D),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.isSubmitting
                  ? null
                  : () {
                      _showEntryDialog();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Timetable Entry',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDaySelector() {
    final rooms = _controller.availableRooms;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Room',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          const SizedBox(height: 9),

          if (rooms.isEmpty)
            const Text('No rooms are available.')
          else
            DropdownButtonFormField<String>(
              initialValue: _controller.selectedRoomName,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.meeting_room_outlined,
                  color: _blue,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: rooms
                  .map(
                    (room) => DropdownMenuItem(value: room, child: Text(room)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _controller.selectRoom(value);
                }
              },
            ),

          const SizedBox(height: 14),

          Row(
            children: AdminTimetableController.weekDays.map((day) {
              final selected = day == _controller.selectedDay;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    _controller.selectDay(day);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          _shortDay(day),
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: selected ? 26 : 0,
                          height: 2,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final room = _controller.selectedRoomName;
    final slots = _controller.availabilitySlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room == null ? 'Room Availability' : '$room Availability',
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _controller.selectedDay,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Color(0xFF7A8289),
          ),
        ),
        const SizedBox(height: 10),

        if (room == null)
          _buildEmptyState(message: 'Select a room to view availability.')
        else
          ...slots.map(_availabilityCard),
      ],
    );
  }

  Widget _availabilityCard(AdminRoomAvailabilitySlot slot) {
    final entry = slot.entry;
    final available = slot.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: available ? _lightGreen : const Color(0xFFEDF6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: available ? _green : _blue),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 62,
            decoration: BoxDecoration(
              color: available ? _green : _blue,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              slot.timeLabel,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: Color(0xFF68727D),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    available
                        ? 'Available'
                        : entry?.subjectName ??
                              entry?.subjectCode ??
                              'Occupied',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: available
                          ? const Color(0xFF5E6D5B)
                          : const Color(0xFF323A40),
                    ),
                  ),
                  if (!available) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry?.lecturer ?? 'Scheduled class',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: Color(0xFF7A8289),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Timetable Entries',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
        ),
        Text(
          '${_filteredEntries.length} shown',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: Color(0xFF7A8289),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _search = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search room, subject or code',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF9DC4DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFBDBD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_controller.errorMessage ?? 'Something went wrong.'),
          ),
        ],
      ),
    );
  }

  List<TimetableModel> get _filteredEntries {
    final room = _controller.selectedRoomName;

    return _controller.entries.where((entry) {
      final matchesRoom =
          room == null ||
          (entry.roomName ?? '').trim().toLowerCase() ==
              room.trim().toLowerCase();

      final matchesDay =
          (entry.day ?? '').trim().toLowerCase() ==
          _controller.selectedDay.toLowerCase();

      final matchesSearch =
          _search.isEmpty ||
          (entry.roomName ?? '').toLowerCase().contains(_search) ||
          (entry.subjectName ?? '').toLowerCase().contains(_search) ||
          (entry.subjectCode ?? '').toLowerCase().contains(_search) ||
          (entry.lecturer ?? '').toLowerCase().contains(_search);

      return matchesRoom && matchesDay && matchesSearch;
    }).toList();
  }

  Widget _entryCard(TimetableModel entry) {
    final lecturer = (entry.lecturer ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9DC4DA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_outlined, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName ?? entry.subjectCode ?? 'Scheduled class',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF323A40),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.roomName ?? 'Unnamed room'}'
                  ' • ${_shortTime(entry.startTime)}'
                  ' - ${_shortTime(entry.endTime)}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Color(0xFF68727D),
                  ),
                ),
                if (lecturer.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    lecturer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Color(0xFF9299A0),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: _controller.isSubmitting
                ? null
                : () {
                    _showEntryDialog(existing: entry);
                  },
            icon: const Icon(Icons.edit_outlined, color: _blue),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _controller.isSubmitting
                ? null
                : () {
                    _confirmDelete(entry);
                  },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntryDialog({TimetableModel? existing}) async {
    final rooms = _controller.availableRooms;

    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No existing rooms are available.')),
        );

      return;
    }

    String initialRoom =
        existing?.roomName?.trim() ??
        _controller.selectedRoomName ??
        rooms.first;

    if (!rooms.contains(initialRoom)) {
      initialRoom = rooms.first;
    }

    final saved = await showDialog<bool>(
      context: context,

      // This avoids the dialog being removed while a save
      // operation is still running.
      barrierDismissible: false,

      builder: (dialogContext) {
        return _TimetableEntryDialog(
          controller: _controller,
          rooms: rooms,
          initialRoom: initialRoom,
          existing: existing,
        );
      },
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Timetable entry added.'
                : 'Timetable entry updated.',
          ),
        ),
      );
  }

  Future<void> _confirmDelete(TimetableModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete timetable entry?',
          style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${entry.subjectName ?? 'This class'} '
          'will be permanently removed from '
          '${entry.roomName ?? 'the timetable'}.',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final success = await _controller.deleteEntry(entry.timetableId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Timetable entry deleted.'
                : _controller.errorMessage ?? 'Unable to delete entry.',
          ),
        ),
      );
  }

  Widget _buildEmptyState({
    String message = 'No timetable entries match this room and day.',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 34,
            color: Color(0xFF9299A0),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Color(0xFF68727D),
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '';
    }

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return text;
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
}

///
/// Add/Edit timetable dialog.
///
/// This is intentionally its own StatefulWidget.
///
/// The previous implementation created TextEditingControllers in
/// _showEntryDialog() and disposed them immediately after showDialog()
/// completed. Flutter can still be animating/rebuilding the dialog route at
/// that point, which caused:
///
/// "A TextEditingController was used after being disposed."
///
/// This widget owns its controllers and disposes them only when Flutter
/// actually disposes the dialog.
///
class _TimetableEntryDialog extends StatefulWidget {
  const _TimetableEntryDialog({
    required this.controller,
    required this.rooms,
    required this.initialRoom,
    this.existing,
  });

  final AdminTimetableController controller;
  final List<String> rooms;
  final String initialRoom;
  final TimetableModel? existing;

  @override
  State<_TimetableEntryDialog> createState() => _TimetableEntryDialogState();
}

class _TimetableEntryDialogState extends State<_TimetableEntryDialog> {
  static const Color _blue = Color(0xFF176F9E);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _subjectController;
  late final TextEditingController _lecturerController;

  late String _selectedRoom;
  late String _day;
  late String _startTime;
  late String _endTime;

  String? _dialogError;
  bool _saving = false;

  TimetableModel? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();

    _selectedRoom = widget.initialRoom;

    _day = _existing?.day ?? 'Monday';

    if (!AdminTimetableController.weekDays.contains(_day)) {
      _day = 'Monday';
    }

    _codeController = TextEditingController(text: _existing?.subjectCode ?? '');

    _subjectController = TextEditingController(
      text: _existing?.subjectName ?? '',
    );

    _lecturerController = TextEditingController(
      text: _existing?.lecturer ?? '',
    );

    _startTime = _shortTime(_existing?.startTime);

    _endTime = _shortTime(_existing?.endTime);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _subjectController.dispose();
    _lecturerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          _existing == null ? 'Add Timetable Entry' : 'Edit Timetable Entry',
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoom,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      'Room',
                      icon: Icons.meeting_room_outlined,
                    ),
                    items: widget.rooms
                        .map(
                          (room) =>
                              DropdownMenuItem(value: room, child: Text(room)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedRoom = value;
                              _dialogError = null;
                            });
                          },
                  ),

                  const SizedBox(height: 10),

                  _field(_codeController, 'Subject Code'),

                  _field(_subjectController, 'Subject Name', required: true),

                  _field(_lecturerController, 'Lecturer'),

                  DropdownButtonFormField<String>(
                    initialValue: _day,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      'Day',
                      icon: Icons.calendar_today_outlined,
                    ),
                    items: AdminTimetableController.weekDays
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _day = value;
                              _dialogError = null;
                            });
                          },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _timeButton(
                          label: 'Start Time',
                          value: _startTime,
                          onPressed: _saving
                              ? null
                              : () {
                                  _chooseTime(start: true);
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _timeButton(
                          label: 'End Time',
                          value: _endTime,
                          onPressed: _saving
                              ? null
                              : () {
                                  _chooseTime(start: false);
                                },
                        ),
                      ),
                    ],
                  ),

                  if (_dialogError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.of(context).pop(false);
                  },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _saveEntry,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_existing == null ? 'Add' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseTime({required bool start}) async {
    final initial = _timeOfDayFromText(
      start ? _startTime : _endTime,
      fallback: start
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 10, minute: 0),
    );

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null || !mounted) {
      return;
    }

    final formatted = _formatTimeOfDay(picked);

    setState(() {
      if (start) {
        _startTime = formatted;
      } else {
        _endTime = formatted;
      }

      _dialogError = null;
    });
  }

  Future<void> _saveEntry() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_startTime.isEmpty || _endTime.isEmpty) {
      setState(() {
        _dialogError = 'Please select start and end times.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _dialogError = null;
    });

    final roomNodeId = widget.controller.roomNodeIdForRoom(_selectedRoom);

    final entry = TimetableModel(
      timetableId: _existing?.timetableId ?? 0,
      roomNodeId: roomNodeId,
      roomName: _selectedRoom,
      subjectCode: _nullableText(_codeController.text),
      subjectName: _subjectController.text.trim(),
      lecturer: _nullableText(_lecturerController.text),
      day: _day,
      startTime: _startTime,
      endTime: _endTime,
    );

    final success = _existing == null
        ? await widget.controller.addEntry(entry)
        : await widget.controller.updateEntry(entry);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _dialogError =
          widget.controller.errorMessage ?? 'Unable to save timetable entry.';
    });
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        decoration: _inputDecoration(label),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }

                return null;
              }
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: _blue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB6D4E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        side: const BorderSide(color: Color(0xFFB6D4E3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: Color(0xFF68727D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Select' : value,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value.isEmpty ? const Color(0xFF9299A0) : _blue,
            ),
          ),
        ],
      ),
    );
  }

  String? _nullableText(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  String _shortTime(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '';
    }

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return text;
  }

  TimeOfDay _timeOfDayFromText(String value, {required TimeOfDay fallback}) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return fallback;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
