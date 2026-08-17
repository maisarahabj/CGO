import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/timetable_model.dart';

class TimetableService {
  TimetableService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _table = 'timetable';

  final SupabaseClient _client;

  /// Loads the master UNIMY timetable.
  Future<List<TimetableModel>> getTimetableEntries() async {
    final List<Map<String, dynamic>> data = await _client.from(_table).select();

    return data.map(TimetableModel.fromJson).toList();
  }

  /// Creates a new timetable entry.
  ///
  /// timetable_id is omitted because it should normally be generated
  /// by the database.
  Future<TimetableModel> addTimetableEntry(TimetableModel entry) async {
    final payload = entry.toJson()
      ..remove('timetable_id')
      ..removeWhere((key, value) => value == null);

    final Map<String, dynamic> row = await _client
        .from(_table)
        .insert(payload)
        .select()
        .single();

    return TimetableModel.fromJson(row);
  }

  /// Updates an existing timetable record.
  Future<TimetableModel> updateTimetableEntry(TimetableModel entry) async {
    final payload = entry.toJson()
      ..remove('timetable_id')
      ..removeWhere((key, value) => value == null);

    final Map<String, dynamic> row = await _client
        .from(_table)
        .update(payload)
        .eq('timetable_id', entry.timetableId)
        .select()
        .single();

    return TimetableModel.fromJson(row);
  }

  /// Deletes one timetable record.
  Future<void> deleteTimetableEntry(int timetableId) async {
    await _client.from(_table).delete().eq('timetable_id', timetableId);
  }
}
