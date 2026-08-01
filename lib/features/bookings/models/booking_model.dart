/// Represents one row from the `public.bookings` table in Supabase.
class BookingModel {
  const BookingModel({
    required this.bookingId,
    this.userId,
    this.bookDate,
    this.bookStartTime,
    this.bookEndTime,
    this.roomNodeId,
    this.sessionType,
    this.additionalInfo,
    this.status,
    this.reason,
    this.createdAt,
  });

  final String bookingId;
  final String? userId;
  final DateTime? bookDate;
  final String? bookStartTime;
  final String? bookEndTime;
  final String? roomNodeId;
  final String? sessionType;
  final String? additionalInfo;
  final String? status;
  final String? reason;
  final DateTime? createdAt;

  /// Converts a Supabase booking row into a BookingModel.
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String?,
      bookDate: _parseOptionalDateTime(json['book_date']),
      bookStartTime: json['book_start_time'] as String?,
      bookEndTime: json['book_end_time'] as String?,
      roomNodeId: json['room_node_id'] as String?,
      sessionType: json['session_type'] as String?,
      additionalInfo: json['additional_info'] as String?,
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      createdAt: _parseOptionalDateTime(json['created_at']),
    );
  }

  /// Converts the model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'book_date': bookDate?.toIso8601String().split('T').first,
      'book_start_time': bookStartTime,
      'book_end_time': bookEndTime,
      'room_node_id': roomNodeId,
      'session_type': sessionType,
      'additional_info': additionalInfo,
      'status': status,
      'reason': reason,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value as String);
  }
}
