import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';
import '../models/home_schedule_snapshot.dart';
import '../models/ongoing_class_model.dart';

/// Reads the small amount of Supabase data required by the home page.
class HomeService {
  HomeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns the class currently in progress and the user's next saved
  /// classes.
  ///
  /// The old implementation only returned classes remaining TODAY. That made
  /// the "Next Classes" section look broken on weekends and after the final
  /// class of the day. This version still detects an ongoing class for today,
  /// but the next-class list is sorted by each timetable entry's next weekly
  /// occurrence.
  Future<HomeScheduleSnapshot> loadTodaySchedule({
    required String userId,
    DateTime? now,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const HomeScheduleSnapshot();
    }

    final currentTime = now ?? DateTime.now();

    final scheduleRows = await _client
        .from(DatabaseTables.mySchedule)
        .select('timetable_id')
        .eq('user_id', cleanUserId);

    final timetableIds = scheduleRows
        .map<int?>((row) {
          final rawValue = row['timetable_id'];

          if (rawValue is num) {
            return rawValue.toInt();
          }

          return int.tryParse(rawValue?.toString().trim() ?? '');
        })
        .whereType<int>()
        .toSet()
        .toList();

    if (timetableIds.isEmpty) {
      return const HomeScheduleSnapshot();
    }

    final timetableRows = await _client
        .from(DatabaseTables.timetable)
        .select(
          'timetable_id, room_node_id, room_name, '
          'subject_name, day, start_time, end_time',
        )
        .inFilter('timetable_id', timetableIds);

    final validRows = <_TimedTimetableRow>[];

    for (final rawRow in timetableRows) {
      final row = Map<String, dynamic>.from(rawRow);
      final timetableId = row['timetable_id']?.toString().trim();
      final dayNumber = _dayNumber(row['day']);
      final startMinutes = _timeToMinutes(row['start_time']);
      final endMinutes = _timeToMinutes(row['end_time']);

      if (timetableId == null ||
          timetableId.isEmpty ||
          dayNumber == null ||
          startMinutes == null ||
          endMinutes == null) {
        continue;
      }

      validRows.add(
        _TimedTimetableRow(
          row: row,
          dayNumber: dayNumber,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
      );
    }

    if (validRows.isEmpty) {
      return const HomeScheduleSnapshot();
    }

    final nowMinutes = currentTime.hour * 60 + currentTime.minute;
    OngoingClassModel? ongoingClass;

    for (final timedRow in validRows) {
      if (timedRow.dayNumber != currentTime.weekday ||
          !timedRow.isOngoingAt(nowMinutes)) {
        continue;
      }

      ongoingClass = await _createClassModel(timedRow);
      break;
    }

    final upcomingRows = <_UpcomingTimetableRow>[];

    for (final timedRow in validRows) {
      final isCurrentOngoingClass =
          timedRow.dayNumber == currentTime.weekday &&
          timedRow.isOngoingAt(nowMinutes);

      if (isCurrentOngoingClass) {
        continue;
      }

      final nextOccurrence = timedRow.nextOccurrenceAt(currentTime);

      if (nextOccurrence == null) {
        continue;
      }

      upcomingRows.add(
        _UpcomingTimetableRow(
          timedRow: timedRow,
          nextOccurrence: nextOccurrence,
        ),
      );
    }

    upcomingRows.sort(
      (first, second) =>
          first.nextOccurrence.compareTo(second.nextOccurrence),
    );

    // The home sheet is a preview. "View All" already opens the complete
    // timetable, so showing the nearest four classes keeps the home panel
    // useful without turning it into another timetable screen.
    final nextClasses = <OngoingClassModel>[];

    for (final upcoming in upcomingRows.take(4)) {
      nextClasses.add(await _createClassModel(upcoming.timedRow));
    }

    return HomeScheduleSnapshot(
      ongoingClass: ongoingClass,
      nextClasses: List.unmodifiable(nextClasses),
    );
  }

  /// Kept for callers that only need the current-class reminder.
  Future<OngoingClassModel?> loadOngoingClass({
    required String userId,
    DateTime? now,
  }) async {
    final schedule = await loadTodaySchedule(userId: userId, now: now);

    return schedule.ongoingClass;
  }

  Future<OngoingClassModel> _createClassModel(
    _TimedTimetableRow timedRow,
  ) async {
    final row = timedRow.row;
    final roomNodeId = row['room_node_id']?.toString().trim() ?? '';

    String? floorId;
    String? nodeLabel;

    if (roomNodeId.isNotEmpty) {
      final node = await _client
          .from(DatabaseTables.nodes)
          .select('floor_id, label')
          .eq('node_id', roomNodeId)
          .maybeSingle();

      floorId = node?['floor_id']?.toString();
      nodeLabel = node?['label']?.toString();
    }

    return OngoingClassModel(
      timetableId: row['timetable_id'].toString(),
      roomNodeId: roomNodeId,
      roomName: _firstUsefulText([row['room_name'], nodeLabel, 'Classroom']),
      subjectName: _firstUsefulText([row['subject_name'], 'Scheduled class']),
      startMinutes: timedRow.startMinutes,
      endMinutes: timedRow.endMinutes,
      floorLabel: _formatFloorLabel(floorId, roomNodeId),
      dayLabel: _formatDayLabel(timedRow.dayNumber),
    );
  }

  int? _dayNumber(Object? rawDay) {
    final day = rawDay?.toString().trim().toLowerCase();

    const dayNumbers = <String, int>{
      'monday': DateTime.monday,
      'mon': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'tue': DateTime.tuesday,
      'tues': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'wed': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'thu': DateTime.thursday,
      'thur': DateTime.thursday,
      'thurs': DateTime.thursday,
      'friday': DateTime.friday,
      'fri': DateTime.friday,
      'saturday': DateTime.saturday,
      'sat': DateTime.saturday,
      'sunday': DateTime.sunday,
      'sun': DateTime.sunday,
    };

    return dayNumbers[day];
  }

  int? _timeToMinutes(Object? value) {
    if (value == null) {
      return null;
    }

    final parts = value.toString().split(':');

    if (parts.length < 2) {
      return null;
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null || minutes == null) {
      return null;
    }

    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
      return null;
    }

    return hours * 60 + minutes;
  }

  String _formatDayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => '',
    };
  }

  String _formatFloorLabel(String? floorId, String roomNodeId) {
    final source = floorId == null || floorId.trim().isEmpty
        ? roomNodeId.split('_').first
        : floorId.trim();

    final normalized = source.toUpperCase();

    if (normalized == 'G' || normalized == 'GROUND') {
      return 'Ground Floor';
    }

    final number = RegExp(r'\d+').firstMatch(normalized)?.group(0);

    return number == null ? source : 'Level $number';
  }

  String _firstUsefulText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();

      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}

class _TimedTimetableRow {
  const _TimedTimetableRow({
    required this.row,
    required this.dayNumber,
    required this.startMinutes,
    required this.endMinutes,
  });

  final Map<String, dynamic> row;
  final int dayNumber;
  final int startMinutes;
  final int endMinutes;

  bool isOngoingAt(int currentMinutes) {
    if (endMinutes >= startMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  DateTime? nextOccurrenceAt(DateTime now) {
    if (dayNumber < DateTime.monday || dayNumber > DateTime.sunday) {
      return null;
    }

    final hour = startMinutes ~/ 60;
    final minute = startMinutes % 60;
    final daysAhead = (dayNumber - now.weekday + 7) % 7;

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
}

class _UpcomingTimetableRow {
  const _UpcomingTimetableRow({
    required this.timedRow,
    required this.nextOccurrence,
  });

  final _TimedTimetableRow timedRow;
  final DateTime nextOccurrence;
}
