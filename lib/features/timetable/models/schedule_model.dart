/// Represents one row from the `public.my_schedule` table.
///
/// A row links one authenticated CampusGO user to one public timetable entry.
class ScheduleModel {
  const ScheduleModel({
    required this.scheduleId,
    this.userId,
    this.timetableId,
  });

  final String scheduleId;
  final String? userId;
  final int? timetableId;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      scheduleId: json['schedule_id'] as String,
      userId: json['user_id'] as String?,
      timetableId: (json['timetable_id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'user_id': userId,
      'timetable_id': timetableId,
    };
  }
}
