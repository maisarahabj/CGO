import 'package:uuid/uuid.dart';
import 'booking_status.dart';

/// Dart representation of one row in the `bookings` Supabase table.
///
/// Column mapping confirmed against Supabase (Table Editor, Aug 2026):
///   booking_id      text (PK, NOT NULL — generated client-side as a UUID string)
///   user_id         uuid
///   book_date       date
///   book_start_time time
///   book_end_time   time
///   room_node_id    text   (FK -> nodes.node_id)
///   session_type    text   (Lecture | Discussion | Lab | Seminar)
///   additional_info text
///   status          text   (see BookingStatus)
///   reason          text   (admin-set, e.g. rejection reason)
///   created_at      timestamptz
class BookingModel {
  final String bookingId;
  final String userId;
  final DateTime bookDate;
  final String bookStartTime; // stored as "HH:mm:ss" text from Supabase `time`
  final String bookEndTime;
  final String roomNodeId;
  final String sessionType;
  final String? additionalInfo;
  final BookingStatus status;
  final String? reason;
  final DateTime createdAt;

  const BookingModel({
    required this.bookingId,
    required this.userId,
    required this.bookDate,
    required this.bookStartTime,
    required this.bookEndTime,
    required this.roomNodeId,
    required this.sessionType,
    this.additionalInfo,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      bookDate: DateTime.parse(json['book_date'] as String),
      bookStartTime: json['book_start_time'] as String,
      bookEndTime: json['book_end_time'] as String,
      roomNodeId: json['room_node_id'] as String,
      sessionType: json['session_type'] as String,
      additionalInfo: json['additional_info'] as String?,
      status: BookingStatus.fromValue(json['status'] as String),
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// For INSERT. Generates a fresh booking_id client-side since the column
  /// is NOT NULL text (not an auto-generated uuid column in Postgres).
  /// created_at is DB-generated (default now()); status is always pending
  /// on creation.
  Map<String, dynamic> toInsertJson() {
    return {
      'booking_id': const Uuid().v4(),
      'user_id': userId,
      'book_date': bookDate.toIso8601String().split('T').first,
      'book_start_time': bookStartTime,
      'book_end_time': bookEndTime,
      'room_node_id': roomNodeId,
      'session_type': sessionType,
      'additional_info': additionalInfo,
      'status': BookingStatus.pending.value,
    };
  }

  /// For UPDATE. Full toJson kept separate from toInsertJson since RLS
  /// restricts which fields a user vs admin may actually change.
  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'book_date': bookDate.toIso8601String().split('T').first,
      'book_start_time': bookStartTime,
      'book_end_time': bookEndTime,
      'room_node_id': roomNodeId,
      'session_type': sessionType,
      'additional_info': additionalInfo,
      'status': status.value,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? userId,
    DateTime? bookDate,
    String? bookStartTime,
    String? bookEndTime,
    String? roomNodeId,
    String? sessionType,
    String? additionalInfo,
    BookingStatus? status,
    String? reason,
    DateTime? createdAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      bookDate: bookDate ?? this.bookDate,
      bookStartTime: bookStartTime ?? this.bookStartTime,
      bookEndTime: bookEndTime ?? this.bookEndTime,
      roomNodeId: roomNodeId ?? this.roomNodeId,
      sessionType: sessionType ?? this.sessionType,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}