import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';
import '../models/home_schedule_snapshot.dart';
import '../models/ongoing_class_model.dart';

/// Reads the small amount of Supabase data required by the home page.
class HomeService {
  HomeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns the class in progress and the user's remaining classes today.
  Future<HomeScheduleSnapshot> loadTodaySchedule({
    required String userId,
    DateTime? now,
  }) async {
    if (userId.trim().isEmpty) return const HomeScheduleSnapshot();

    final currentTime = now ?? DateTime.now();
    final scheduleRows = await _client
        .from(DatabaseTables.mySchedule)
        .select('timetable_id')
        .eq('user_id', userId);

    final timetableIds = scheduleRows
        .map((row) => row['timetable_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (timetableIds.isEmpty) return const HomeScheduleSnapshot();

    final timetableRows = await _client
        .from(DatabaseTables.timetable)
        .select(
          'timetable_id, room_node_id, room_name, subject_name, day, '
          'start_time, end_time',
        )
        .inFilter('timetable_id', timetableIds);

    final todayRows = <_TimedTimetableRow>[];

    for (final rawRow in timetableRows) {
      final row = Map<String, dynamic>.from(rawRow);
      if (!_isSameWeekday(row['day'], currentTime.weekday)) continue;

      final startMinutes = _timeToMinutes(row['start_time']);
      final endMinutes = _timeToMinutes(row['end_time']);
      final timetableId = row['timetable_id']?.toString().trim();

      if (startMinutes == null ||
          endMinutes == null ||
          timetableId == null ||
          timetableId.isEmpty) {
        continue;
      }

      todayRows.add(
        _TimedTimetableRow(
          row: row,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
      );
    }

    todayRows.sort(
      (first, second) => first.startMinutes.compareTo(second.startMinutes),
    );

    final nowMinutes = currentTime.hour * 60 + currentTime.minute;
    OngoingClassModel? ongoingClass;
    final nextClasses = <OngoingClassModel>[];

    for (final timedRow in todayRows) {
      final isOngoing = timedRow.isOngoingAt(nowMinutes);
      final isUpcoming = timedRow.startsAfter(nowMinutes);

      if (!isOngoing && !isUpcoming) continue;

      final classModel = await _createClassModel(timedRow);

      if (isOngoing && ongoingClass == null) {
        ongoingClass = classModel;
      } else if (isUpcoming) {
        nextClasses.add(classModel);
      }
    }

    return HomeScheduleSnapshot(
      ongoingClass: ongoingClass,
      nextClasses: List.unmodifiable(nextClasses),
    );
  }

  /// Kept for callers that only need the current class reminder.
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

      floorId = node?['floor_id'] as String?;
      nodeLabel = node?['label'] as String?;
    }

    return OngoingClassModel(
      timetableId: row['timetable_id'].toString(),
      roomNodeId: roomNodeId,
      roomName: _firstUsefulText([row['room_name'], nodeLabel, 'Classroom']),
      subjectName: _firstUsefulText([row['subject_name'], 'Scheduled class']),
      startMinutes: timedRow.startMinutes,
      endMinutes: timedRow.endMinutes,
      floorLabel: _formatFloorLabel(floorId, roomNodeId),
    );
  }

  bool _isSameWeekday(Object? rawDay, int weekday) {
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

    return dayNumbers[day] == weekday;
  }

  int? _timeToMinutes(Object? value) {
    if (value == null) return null;

    final parts = value.toString().split(':');
    if (parts.length < 2) return null;

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;

    return hours * 60 + minutes;
  }

  String _formatFloorLabel(String? floorId, String roomNodeId) {
    final source = (floorId == null || floorId.trim().isEmpty)
        ? roomNodeId.split('_').first
        : floorId.trim();
    final normalized = source.toUpperCase();

    if (normalized == 'G' || normalized == 'GROUND') return 'Ground Floor';

    final number = RegExp(r'\d+').firstMatch(normalized)?.group(0);
    return number == null ? source : 'Level $number';
  }

  String _firstUsefulText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }
}

class _TimedTimetableRow {
  const _TimedTimetableRow({
    required this.row,
    required this.startMinutes,
    required this.endMinutes,
  });

  final Map<String, dynamic> row;
  final int startMinutes;
  final int endMinutes;

  bool isOngoingAt(int currentMinutes) {
    if (endMinutes >= startMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  bool startsAfter(int currentMinutes) {
    return currentMinutes < startMinutes;
  }
}
