import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_model.dart';
import '../models/timetable_model.dart';

class ScheduleService {
  ScheduleService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _scheduleTable = 'my_schedule';
  static const String _timetableTable = 'timetable';

  final SupabaseClient _client;

  String get currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'A registered user must be signed in to access My Schedule.',
      );
    }

    return user.id;
  }

  /// Returns the signed-in user's rows from public.my_schedule.
  Future<List<ScheduleModel>> getMyScheduleLinks() async {
    final List<Map<String, dynamic>> data = await _client
        .from(_scheduleTable)
        .select()
        .eq('user_id', currentUserId);

    return data.map(ScheduleModel.fromJson).toList();
  }

  /// Returns the timetable records referenced by the user's saved schedule.
  Future<List<TimetableModel>> getMyTimetableEntries() async {
    final scheduleRows = await getMyScheduleLinks();

    final timetableIds = scheduleRows
        .map((row) => row.timetableId)
        .whereType<int>()
        .toSet()
        .toList();

    if (timetableIds.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> data = await _client
        .from(_timetableTable)
        .select()
        .inFilter('timetable_id', timetableIds);

    return data.map(TimetableModel.fromJson).toList();
  }

  /// Returns true when this exact timetable entry is already saved
  /// by the current authenticated user.
  Future<bool> isSaved(int timetableId) async {
    final List<Map<String, dynamic>> data = await _client
        .from(_scheduleTable)
        .select('schedule_id')
        .eq('user_id', currentUserId)
        .eq('timetable_id', timetableId)
        .limit(1);

    return data.isNotEmpty;
  }

  /// Saves a timetable entry for the current user.
  ///
  /// The database requires schedule_id, but it has no default generator.
  /// A deterministic ID also helps stop rapid duplicate inserts.
  Future<void> saveTimetableEntry(int timetableId) async {
    if (await isSaved(timetableId)) {
      return;
    }

    final scheduleId = _buildScheduleId(timetableId);

    try {
      await _client.from(_scheduleTable).insert({
        'schedule_id': scheduleId,
        'user_id': currentUserId,
        'timetable_id': timetableId,
      });
    } on PostgrestException catch (error) {
      // PostgreSQL unique_violation.
      // If two save requests arrive almost simultaneously, the
      // deterministic primary key prevents a duplicate row.
      if (error.code == '23505') {
        return;
      }

      rethrow;
    }
  }

  /// Removes only the current user's saved relationship.
  ///
  /// It never deletes the actual public timetable record.
  Future<void> removeTimetableEntry(int timetableId) async {
    await _client
        .from(_scheduleTable)
        .delete()
        .eq('user_id', currentUserId)
        .eq('timetable_id', timetableId);
  }

  String _buildScheduleId(int timetableId) {
    return '${currentUserId}_$timetableId';
  }
}
