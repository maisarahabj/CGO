import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/timetable_model.dart';
import '../services/timetable_service.dart';

class RoomAvailabilitySlot {
  const RoomAvailabilitySlot({
    required this.startMinutes,
    required this.endMinutes,
    this.entry,
  });

  final int startMinutes;
  final int endMinutes;
  final TimetableModel? entry;

  bool get isAvailable => entry == null;

  String get startLabel => _formatMinutes(startMinutes);

  String get endLabel => _formatMinutes(endMinutes);

  String get timeLabel => '$startLabel - $endLabel';

  static String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

class TimetableController extends ChangeNotifier {
  TimetableController({TimetableService? service})
    : _service = service ?? TimetableService();

  final TimetableService _service;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  List<TimetableModel> _entries = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedDay = 'Monday';
  String? _selectedRoomName;

  List<TimetableModel> get entries => List.unmodifiable(_entries);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;

  String get selectedDay => _selectedDay;

  String? get selectedRoomName => _selectedRoomName;

  List<String> get availableRooms {
    final rooms = _entries
        .map((entry) => entry.roomName?.trim())
        .whereType<String>()
        .where((room) => room.isNotEmpty)
        .toSet()
        .toList();

    rooms.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return rooms;
  }

  /// Used by the search field.
  ///
  /// Users can search by:
  /// - room
  /// - subject name
  /// - subject code
  /// - lecturer
  List<TimetableModel> get searchResults {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    final results = _entries.where((entry) {
      return _contains(entry.roomName, query) ||
          _contains(entry.subjectName, query) ||
          _contains(entry.subjectCode, query) ||
          _contains(entry.lecturer, query);
    }).toList();

    return results.take(8).toList();
  }

  List<TimetableModel> get selectedRoomEntries {
    final room = _selectedRoomName;

    if (room == null) {
      return [];
    }

    final result = _entries.where((entry) {
      return entry.roomName?.trim().toLowerCase() ==
              room.trim().toLowerCase() &&
          entry.day?.trim().toLowerCase() == _selectedDay.toLowerCase();
    }).toList();

    result.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    return result;
  }

  /// Converts the selected room's timetable into:
  ///
  /// Available
  /// Available
  /// Class
  /// Available
  /// Class
  ///
  /// as shown in the Figma room timetable.
  List<RoomAvailabilitySlot> get availabilitySlots {
    final roomEntries = selectedRoomEntries;

    const normalOpeningTime = 9 * 60;
    const normalClosingTime = 18 * 60;

    if (roomEntries.isEmpty) {
      return const [
        RoomAvailabilitySlot(
          startMinutes: normalOpeningTime,
          endMinutes: normalClosingTime,
        ),
      ];
    }

    final earliestClass = _timeToMinutes(roomEntries.first.startTime);

    final latestClass = roomEntries
        .map((entry) => _timeToMinutes(entry.endTime))
        .fold(normalClosingTime, max);

    int cursor = min(normalOpeningTime, earliestClass);
    final closingTime = max(normalClosingTime, latestClass);

    final slots = <RoomAvailabilitySlot>[];

    for (final entry in roomEntries) {
      final start = _timeToMinutes(entry.startTime);
      final end = _timeToMinutes(entry.endTime);

      if (end <= start) {
        continue;
      }

      if (start > cursor) {
        slots.add(
          RoomAvailabilitySlot(startMinutes: cursor, endMinutes: start),
        );
      }

      slots.add(
        RoomAvailabilitySlot(
          startMinutes: start,
          endMinutes: end,
          entry: entry,
        ),
      );

      cursor = max(cursor, end);
    }

    if (cursor < closingTime) {
      slots.add(
        RoomAvailabilitySlot(startMinutes: cursor, endMinutes: closingTime),
      );
    }

    return slots;
  }

  Future<void> loadTimetable() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _service.getTimetableEntries();

      _entries.sort((a, b) {
        final dayComparison = _dayNumber(a.day).compareTo(_dayNumber(b.day));

        if (dayComparison != 0) {
          return dayComparison;
        }

        return _timeToMinutes(
          a.startTime,
        ).compareTo(_timeToMinutes(b.startTime));
      });

      _selectedDay = _defaultDay();

      final rooms = availableRooms;

      if (_selectedRoomName == null && rooms.isNotEmpty) {
        _selectedRoomName = rooms.first;
      }
    } catch (error) {
      debugPrint('Timetable load error: $error');

      _errorMessage = 'Unable to load the timetable. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void selectSearchResult(TimetableModel entry) {
    final room = entry.roomName?.trim();

    if (room == null || room.isEmpty) {
      return;
    }

    _selectedRoomName = room;

    final entryDay = _normaliseDay(entry.day);

    if (weekDays.contains(entryDay)) {
      _selectedDay = entryDay;
    }

    _searchQuery = '';
    notifyListeners();
  }

  void selectRoom(String roomName) {
    _selectedRoomName = roomName;
    _searchQuery = '';
    notifyListeners();
  }

  void setDayFilter(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedDay = _defaultDay();

    final rooms = availableRooms;

    if (rooms.isNotEmpty) {
      _selectedRoomName = rooms.first;
    }

    notifyListeners();
  }

  bool isEntryOngoing(TimetableModel entry) {
    final now = DateTime.now();

    if (_dayNumber(entry.day) != now.weekday) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;

    final start = _timeToMinutes(entry.startTime);
    final end = _timeToMinutes(entry.endTime);

    return currentMinutes >= start && currentMinutes < end;
  }

  bool _contains(String? value, String query) {
    return (value ?? '').trim().toLowerCase().contains(query);
  }

  String _defaultDay() {
    final weekday = DateTime.now().weekday;

    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      return weekDays[weekday - 1];
    }

    return 'Monday';
  }

  String _normaliseDay(String? day) {
    switch (day?.trim().toLowerCase()) {
      case 'mon':
      case 'monday':
        return 'Monday';

      case 'tue':
      case 'tues':
      case 'tuesday':
        return 'Tuesday';

      case 'wed':
      case 'wednesday':
        return 'Wednesday';

      case 'thu':
      case 'thur':
      case 'thurs':
      case 'thursday':
        return 'Thursday';

      case 'fri':
      case 'friday':
        return 'Friday';

      default:
        return day?.trim() ?? '';
    }
  }

  int _dayNumber(String? day) {
    switch (_normaliseDay(day)) {
      case 'Monday':
        return DateTime.monday;

      case 'Tuesday':
        return DateTime.tuesday;

      case 'Wednesday':
        return DateTime.wednesday;

      case 'Thursday':
        return DateTime.thursday;

      case 'Friday':
        return DateTime.friday;

      default:
        return 99;
    }
  }

  int _timeToMinutes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 0;
    }

    final text = value.trim().toUpperCase();

    final isPm = text.contains('PM');
    final isAm = text.contains('AM');

    final clean = text.replaceAll('AM', '').replaceAll('PM', '').trim();

    final parts = clean.split(':');

    if (parts.length < 2) {
      return 0;
    }

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPm && hour != 12) {
      hour += 12;
    }

    if (isAm && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }
}
