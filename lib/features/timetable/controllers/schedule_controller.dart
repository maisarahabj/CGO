import 'package:flutter/foundation.dart';

import '../models/timetable_model.dart';
import '../services/schedule_service.dart';

enum SaveScheduleResult { added, alreadySaved, failed }

class ScheduleController extends ChangeNotifier {
  ScheduleController({ScheduleService? service})
    : _service = service ?? ScheduleService();

  final ScheduleService _service;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  List<TimetableModel> _entries = [];

  final Set<int> _busyEntries = {};

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedDay = 'Monday';

  List<TimetableModel> get entries {
    return List.unmodifiable(_entries);
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get selectedDay => _selectedDay;

  List<TimetableModel> get selectedDayEntries {
    final result = _entries.where((entry) {
      return _dayNumber(entry.day) == _dayNumber(_selectedDay);
    }).toList();

    result.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    return result;
  }

  TimetableModel? get currentClass {
    return currentClassAt(DateTime.now());
  }

  TimetableModel? get nextClass {
    return nextClassAt(DateTime.now());
  }

  List<TimetableModel> get upcomingClassesToday {
    return upcomingClassesTodayAt(DateTime.now());
  }

  Future<void> loadSchedule() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _entries = await _service.getMyTimetableEntries();

      _sortEntries();

      final today = DateTime.now().weekday;

      if (today >= DateTime.monday && today <= DateTime.friday) {
        _selectedDay = weekDays[today - 1];
      }
    } catch (error) {
      debugPrint('Schedule load error: $error');

      _errorMessage = 'Unable to load your schedule. Please try again.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  void setSelectedDay(String day) {
    if (!weekDays.contains(day)) {
      return;
    }

    if (_selectedDay == day) {
      return;
    }

    _selectedDay = day;

    notifyListeners();
  }

  bool isSaved(int timetableId) {
    return _entries.any((entry) => entry.timetableId == timetableId);
  }

  bool isBusy(int timetableId) {
    return _busyEntries.contains(timetableId);
  }

  Future<SaveScheduleResult> saveEntry(int timetableId) async {
    if (isSaved(timetableId)) {
      return SaveScheduleResult.alreadySaved;
    }

    if (_busyEntries.contains(timetableId)) {
      return SaveScheduleResult.alreadySaved;
    }

    _busyEntries.add(timetableId);
    _errorMessage = null;

    notifyListeners();

    try {
      if (await _service.isSaved(timetableId)) {
        await _reloadEntriesWithoutLoadingState();

        return SaveScheduleResult.alreadySaved;
      }

      await _service.saveTimetableEntry(timetableId);

      await _reloadEntriesWithoutLoadingState();

      return SaveScheduleResult.added;
    } catch (error) {
      debugPrint('Save schedule error: $error');

      _errorMessage = 'Unable to save this class to your schedule.';

      return SaveScheduleResult.failed;
    } finally {
      _busyEntries.remove(timetableId);

      notifyListeners();
    }
  }

  Future<bool> removeEntry(int timetableId) async {
    if (_busyEntries.contains(timetableId)) {
      return false;
    }

    _busyEntries.add(timetableId);
    _errorMessage = null;

    notifyListeners();

    try {
      await _service.removeTimetableEntry(timetableId);

      _entries.removeWhere((entry) => entry.timetableId == timetableId);

      _sortEntries();

      return true;
    } catch (error) {
      debugPrint('Remove schedule error: $error');

      _errorMessage = 'Unable to remove this class from your schedule.';

      return false;
    } finally {
      _busyEntries.remove(timetableId);

      notifyListeners();
    }
  }

  /// Testable version of currentClass.
  ///
  /// This is useful because TCD23 can test a known Monday/Tuesday time
  /// without changing production logic.
  TimetableModel? currentClassAt(DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;

    final todayEntries = _entries.where(
      (entry) => _dayNumber(entry.day) == now.weekday,
    );

    for (final entry in todayEntries) {
      final start = _timeToMinutes(entry.startTime);
      final end = _timeToMinutes(entry.endTime);

      if (nowMinutes >= start && nowMinutes < end) {
        return entry;
      }
    }

    return null;
  }

  /// Returns the nearest future saved class, including later weekdays.
  TimetableModel? nextClassAt(DateTime now) {
    TimetableModel? result;
    DateTime? resultDate;

    for (final entry in _entries) {
      final occurrence = _nextOccurrence(entry, now);

      if (occurrence == null) {
        continue;
      }

      if (resultDate == null || occurrence.isBefore(resultDate)) {
        result = entry;
        resultDate = occurrence;
      }
    }

    return result;
  }

  /// Classes still remaining TODAY.
  ///
  /// This matches HomeScreen's `nextClasses` contract.
  List<TimetableModel> upcomingClassesTodayAt(DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;

    final result = _entries.where((entry) {
      if (_dayNumber(entry.day) != now.weekday) {
        return false;
      }

      return _timeToMinutes(entry.startTime) > nowMinutes;
    }).toList();

    result.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    return result;
  }

  Future<void> _reloadEntriesWithoutLoadingState() async {
    _entries = await _service.getMyTimetableEntries();

    _sortEntries();
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      final dayCompare = _dayNumber(a.day).compareTo(_dayNumber(b.day));

      if (dayCompare != 0) {
        return dayCompare;
      }

      return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
    });
  }

  DateTime? _nextOccurrence(TimetableModel entry, DateTime now) {
    final weekday = _dayNumber(entry.day);

    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return null;
    }

    final startMinutes = _timeToMinutes(entry.startTime);

    final hour = startMinutes ~/ 60;
    final minute = startMinutes % 60;

    final daysAhead = (weekday - now.weekday + 7) % 7;

    var occurrence = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );

    if (!occurrence.isAfter(now)) {
      occurrence = occurrence.add(const Duration(days: 7));
    }

    return occurrence;
  }

  int _dayNumber(String? day) {
    switch (day?.trim().toLowerCase()) {
      case 'monday':
      case 'mon':
        return DateTime.monday;

      case 'tuesday':
      case 'tue':
      case 'tues':
        return DateTime.tuesday;

      case 'wednesday':
      case 'wed':
        return DateTime.wednesday;

      case 'thursday':
      case 'thu':
      case 'thur':
      case 'thurs':
        return DateTime.thursday;

      case 'friday':
      case 'fri':
        return DateTime.friday;

      case 'saturday':
      case 'sat':
        return DateTime.saturday;

      case 'sunday':
      case 'sun':
        return DateTime.sunday;

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
