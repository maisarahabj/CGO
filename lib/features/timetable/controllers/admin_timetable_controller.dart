import 'package:flutter/foundation.dart';

import '../models/timetable_model.dart';
import '../services/timetable_service.dart';

class AdminRoomAvailabilitySlot {
  const AdminRoomAvailabilitySlot({
    required this.startMinutes,
    required this.endMinutes,
    this.entry,
  });

  final int startMinutes;
  final int endMinutes;
  final TimetableModel? entry;

  bool get isAvailable => entry == null;

  String get timeLabel =>
      '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}';

  static String _formatMinutes(int totalMinutes) {
    final hour = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class AdminTimetableController extends ChangeNotifier {
  AdminTimetableController({TimetableService? service})
    : _service = service ?? TimetableService();

  final TimetableService _service;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const int timetableStartMinutes = 9 * 60;
  static const int timetableEndMinutes = 18 * 60;

  List<TimetableModel> _entries = [];

  bool _isLoading = false;
  bool _isSubmitting = false;

  String? _errorMessage;
  String? _selectedRoomName;
  String _selectedDay = 'Monday';

  List<TimetableModel> get entries => List.unmodifiable(_entries);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  String? get selectedRoomName => _selectedRoomName;

  String get selectedDay => _selectedDay;

  List<String> get availableRooms {
    final roomMap = <String, String>{};

    for (final entry in _entries) {
      final room = entry.roomName?.trim() ?? '';

      if (room.isEmpty) {
        continue;
      }

      roomMap.putIfAbsent(room.toLowerCase(), () => room);
    }

    final rooms = roomMap.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return rooms;
  }

  List<TimetableModel> get selectedRoomDayEntries {
    final room = _selectedRoomName;

    if (room == null || room.trim().isEmpty) {
      return [];
    }

    final result = _entries.where((entry) {
      return _sameText(entry.roomName, room) &&
          _sameText(entry.day, _selectedDay);
    }).toList();

    result.sort(
      (a, b) => (_timeToMinutes(a.startTime) ?? 0).compareTo(
        _timeToMinutes(b.startTime) ?? 0,
      ),
    );

    return result;
  }

  List<AdminRoomAvailabilitySlot> get availabilitySlots {
    final occupiedEntries = selectedRoomDayEntries;

    if (occupiedEntries.isEmpty) {
      return const [
        AdminRoomAvailabilitySlot(
          startMinutes: timetableStartMinutes,
          endMinutes: timetableEndMinutes,
        ),
      ];
    }

    final slots = <AdminRoomAvailabilitySlot>[];

    var cursor = timetableStartMinutes;

    for (final entry in occupiedEntries) {
      final rawStart = _timeToMinutes(entry.startTime);

      final rawEnd = _timeToMinutes(entry.endTime);

      if (rawStart == null || rawEnd == null) {
        continue;
      }

      final start = rawStart.clamp(timetableStartMinutes, timetableEndMinutes);

      final end = rawEnd.clamp(timetableStartMinutes, timetableEndMinutes);

      if (end <= start) {
        continue;
      }

      if (start > cursor) {
        slots.add(
          AdminRoomAvailabilitySlot(startMinutes: cursor, endMinutes: start),
        );
      }

      slots.add(
        AdminRoomAvailabilitySlot(
          startMinutes: start,
          endMinutes: end,
          entry: entry,
        ),
      );

      if (end > cursor) {
        cursor = end;
      }
    }

    if (cursor < timetableEndMinutes) {
      slots.add(
        AdminRoomAvailabilitySlot(
          startMinutes: cursor,
          endMinutes: timetableEndMinutes,
        ),
      );
    }

    return slots;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _entries = await _service.getTimetableEntries();

      _sortEntries();
      _ensureSelectedRoom();
    } catch (error) {
      debugPrint('Admin timetable load error: $error');

      _errorMessage = 'Unable to load timetable management data.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  void selectRoom(String roomName) {
    final room = roomName.trim();

    if (room.isEmpty) {
      return;
    }

    _selectedRoomName = room;

    notifyListeners();
  }

  void selectDay(String day) {
    if (!weekDays.contains(day)) {
      return;
    }

    _selectedDay = day;

    notifyListeners();
  }

  String? roomNodeIdForRoom(String roomName) {
    final wantedRoom = roomName.trim().toLowerCase();

    for (final entry in _entries) {
      if ((entry.roomName ?? '').trim().toLowerCase() != wantedRoom) {
        continue;
      }

      final nodeId = entry.roomNodeId?.trim();

      if (nodeId != null && nodeId.isNotEmpty) {
        return nodeId;
      }
    }

    return null;
  }

  String? validateEntry(TimetableModel entry) {
    if ((entry.roomName ?? '').trim().isEmpty) {
      return 'Please select a room.';
    }

    if ((entry.subjectName ?? '').trim().isEmpty) {
      return 'Please enter a subject name.';
    }

    final day = entry.day?.trim() ?? '';

    if (!weekDays.contains(day)) {
      return 'Please select a valid weekday.';
    }

    final start = _timeToMinutes(entry.startTime);

    final end = _timeToMinutes(entry.endTime);

    if (start == null || end == null) {
      return 'Please enter valid start and end times.';
    }

    if (end <= start) {
      return 'End time must be later than start time.';
    }

    return null;
  }

  Future<bool> addEntry(TimetableModel entry) async {
    _errorMessage = null;

    final validationError = validateEntry(entry);

    if (validationError != null) {
      _errorMessage = validationError;

      notifyListeners();

      return false;
    }

    if (!isRoomAvailable(
      roomNodeId: entry.roomNodeId,
      roomName: entry.roomName ?? '',
      day: entry.day ?? '',
      startTime: entry.startTime ?? '',
      endTime: entry.endTime ?? '',
    )) {
      _errorMessage =
          'This room already has a class during '
          'the selected time.';

      notifyListeners();

      return false;
    }

    _isSubmitting = true;

    notifyListeners();

    try {
      final created = await _service.addTimetableEntry(entry);

      _entries.add(created);

      _sortEntries();

      _selectedRoomName = created.roomName?.trim();

      if (created.day != null && weekDays.contains(created.day)) {
        _selectedDay = created.day!;
      }

      notifyListeners();

      return true;
    } catch (error) {
      debugPrint('Add timetable error: $error');

      _errorMessage = 'Unable to create the timetable entry.';

      notifyListeners();

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  Future<bool> updateEntry(TimetableModel entry) async {
    _errorMessage = null;

    final validationError = validateEntry(entry);

    if (validationError != null) {
      _errorMessage = validationError;

      notifyListeners();

      return false;
    }

    if (!isRoomAvailable(
      roomNodeId: entry.roomNodeId,
      roomName: entry.roomName ?? '',
      day: entry.day ?? '',
      startTime: entry.startTime ?? '',
      endTime: entry.endTime ?? '',
      excludingTimetableId: entry.timetableId,
    )) {
      _errorMessage =
          'This room already has a class during '
          'the selected time.';

      notifyListeners();

      return false;
    }

    _isSubmitting = true;

    notifyListeners();

    try {
      final updated = await _service.updateTimetableEntry(entry);

      final index = _entries.indexWhere(
        (item) => item.timetableId == updated.timetableId,
      );

      if (index != -1) {
        _entries[index] = updated;
      }

      _sortEntries();

      _selectedRoomName = updated.roomName?.trim();

      if (updated.day != null && weekDays.contains(updated.day)) {
        _selectedDay = updated.day!;
      }

      notifyListeners();

      return true;
    } catch (error) {
      debugPrint('Update timetable error: $error');

      _errorMessage = 'Unable to update the timetable entry.';

      notifyListeners();

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  Future<bool> deleteEntry(int timetableId) async {
    _isSubmitting = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.deleteTimetableEntry(timetableId);

      _entries.removeWhere((entry) => entry.timetableId == timetableId);

      _ensureSelectedRoom();

      notifyListeners();

      return true;
    } catch (error) {
      debugPrint('Delete timetable error: $error');

      _errorMessage = 'Unable to delete the timetable entry.';

      notifyListeners();

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  bool isRoomAvailable({
    String? roomNodeId,
    required String roomName,
    required String day,
    required String startTime,
    required String endTime,
    int? excludingTimetableId,
  }) {
    final proposedStart = _timeToMinutes(startTime);

    final proposedEnd = _timeToMinutes(endTime);

    if (proposedStart == null ||
        proposedEnd == null ||
        proposedEnd <= proposedStart) {
      return false;
    }

    for (final entry in _entries) {
      if (entry.timetableId == excludingTimetableId) {
        continue;
      }

      if (!_isSameRoom(
        existing: entry,
        proposedNodeId: roomNodeId,
        proposedRoomName: roomName,
      )) {
        continue;
      }

      if (!_sameText(entry.day, day)) {
        continue;
      }

      final existingStart = _timeToMinutes(entry.startTime);

      final existingEnd = _timeToMinutes(entry.endTime);

      if (existingStart == null || existingEnd == null) {
        continue;
      }

      final overlaps =
          proposedStart < existingEnd && proposedEnd > existingStart;

      if (overlaps) {
        return false;
      }
    }

    return true;
  }

  void _ensureSelectedRoom() {
    final rooms = availableRooms;

    if (rooms.isEmpty) {
      _selectedRoomName = null;

      return;
    }

    final current = _selectedRoomName?.trim() ?? '';

    final stillExists = rooms.any(
      (room) => room.toLowerCase() == current.toLowerCase(),
    );

    if (!stillExists) {
      _selectedRoomName = rooms.first;
    }
  }

  bool _isSameRoom({
    required TimetableModel existing,
    required String? proposedNodeId,
    required String proposedRoomName,
  }) {
    final existingNode = existing.roomNodeId?.trim() ?? '';

    final proposedNode = proposedNodeId?.trim() ?? '';

    if (existingNode.isNotEmpty && proposedNode.isNotEmpty) {
      return existingNode.toLowerCase() == proposedNode.toLowerCase();
    }

    return _sameText(existing.roomName, proposedRoomName);
  }

  bool _sameText(String? first, String? second) {
    return (first ?? '').trim().toLowerCase() ==
        (second ?? '').trim().toLowerCase();
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      final dayCompare = _dayIndex(a.day).compareTo(_dayIndex(b.day));

      if (dayCompare != 0) {
        return dayCompare;
      }

      return (_timeToMinutes(a.startTime) ?? 0).compareTo(
        _timeToMinutes(b.startTime) ?? 0,
      );
    });
  }

  int _dayIndex(String? day) {
    switch (day?.trim().toLowerCase()) {
      case 'monday':
      case 'mon':
        return 1;

      case 'tuesday':
      case 'tue':
      case 'tues':
        return 2;

      case 'wednesday':
      case 'wed':
        return 3;

      case 'thursday':
      case 'thu':
      case 'thur':
      case 'thurs':
        return 4;

      case 'friday':
      case 'fri':
        return 5;

      default:
        return 99;
    }
  }

  int? _timeToMinutes(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final parts = text.split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return hour * 60 + minute;
  }
}
