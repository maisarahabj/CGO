/// Represents one row from the `public.my_schedule` table.
///
/// A schedule row connects a CampusGO user to one timetable record.
class ScheduleModel {
  const ScheduleModel({
    required this.scheduleId,
    this.userId,
    this.timetableId,
  });

  final String scheduleId;
  final String? userId;
  final int? timetableId;

  /// Converts one Supabase my_schedule row into a ScheduleModel.
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      scheduleId: json['schedule_id'] as String,
      userId: json['user_id'] as String?,
      timetableId: (json['timetable_id'] as num?)?.toInt(),
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'user_id': userId,
      'timetable_id': timetableId,
    };
  }
}
