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

  TimetableModel copyWith({
    int? timetableId,
    String? roomNodeId,
    String? roomName,
    String? subjectCode,
    String? subjectName,
    String? lecturer,
    String? day,
    String? startTime,
    String? endTime,
  }) {
    return TimetableModel(
      timetableId: timetableId ?? this.timetableId,
      roomNodeId: roomNodeId ?? this.roomNodeId,
      roomName: roomName ?? this.roomName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      lecturer: lecturer ?? this.lecturer,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
