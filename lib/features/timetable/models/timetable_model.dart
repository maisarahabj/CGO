/// Represents one class session from the `public.timetable` table.
class TimetableModel {
  const TimetableModel({
    required this.timetableId,
    this.roomNodeId,
    this.roomName,
    this.subjectCode,
    this.subjectName,
    this.lecturer,
    this.day,
    this.startTime,
    this.endTime,
  });

  final int timetableId;
  final String? roomNodeId;
  final String? roomName;
  final String? subjectCode;
  final String? subjectName;
  final String? lecturer;
  final String? day;
  final String? startTime;
  final String? endTime;

  /// Converts one Supabase timetable row into a TimetableModel.
  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      timetableId: (json['timetable_id'] as num).toInt(),
      roomNodeId: json['room_node_id'] as String?,
      roomName: json['room_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      lecturer: json['lecturer'] as String?,
      day: json['day'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'timetable_id': timetableId,
      'room_node_id': roomNodeId,
      'room_name': roomName,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'lecturer': lecturer,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}
