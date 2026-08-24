import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';

class BookingService {
  final SupabaseClient _client;

  BookingService(this._client);

  static const String _table = 'bookings';
  static const String _nodesTable = 'nodes';
  static const String _timetableTable = 'timetable';

  Future<List<Map<String, String>>> fetchClassroomRooms() async {
    final response = await _client
        .from(_nodesTable)
        .select('node_id, label')
        .eq('node_type', 'classroom')
        .order('label', ascending: true);

    return (response as List)
        .map((row) => {
              'node_id': row['node_id'] as String,
              'label': row['label'] as String,
            })
        .toList();
  }

  /// Returns only the classroom rooms that are free for the given date +
  /// time range — i.e. not already covered by a recurring timetable class
  /// on that day of week, and not already pending/approved-booked for
  /// that exact date and overlapping time.
  ///
  /// `timetable.day` is stored as a weekday name (e.g. "Monday"), not a
  /// specific date, since it's a recurring weekly schedule — so the day
  /// name is derived from `date` here rather than queried directly.
  Future<List<Map<String, String>>> fetchAvailableRooms({
    required DateTime date,
    required String startTime, // "HH:mm:ss"
    required String endTime,
  }) async {
    final allRooms = await fetchClassroomRooms();
    final dayName = _weekdayName(date.weekday);

    // Timetable conflicts: recurring classes on this weekday that overlap
    // the requested time range.
    final timetableRows = await _client
        .from(_timetableTable)
        .select('room_node_id, start_time, end_time')
        .eq('day', dayName);

    final blockedByTimetable = <String>{};
    for (final row in (timetableRows as List)) {
      final rNodeId = row['room_node_id'] as String;
      final rStart = row['start_time'] as String;
      final rEnd = row['end_time'] as String;
      if (_timesOverlap(startTime, endTime, rStart, rEnd)) {
        blockedByTimetable.add(rNodeId);
      }
    }

    // Booking conflicts: existing pending/approved bookings on this exact
    // date that overlap the requested time range.
    final dateStr = date.toIso8601String().split('T').first;
    final bookingRows = await _client
        .from(_table)
        .select('room_node_id, book_start_time, book_end_time, status')
        .eq('book_date', dateStr)
        .inFilter('status', [BookingStatus.pending.value, BookingStatus.approved.value]);

    final blockedByBookings = <String>{};
    for (final row in (bookingRows as List)) {
      final rNodeId = row['room_node_id'] as String;
      final rStart = row['book_start_time'] as String;
      final rEnd = row['book_end_time'] as String;
      if (_timesOverlap(startTime, endTime, rStart, rEnd)) {
        blockedByBookings.add(rNodeId);
      }
    }

    final blocked = {...blockedByTimetable, ...blockedByBookings};
    return allRooms.where((room) => !blocked.contains(room['node_id'])).toList();
  }

  bool _timesOverlap(String startA, String endA, String startB, String endB) {
    // "HH:mm:ss" strings compare correctly as plain strings since they're
    // fixed-width and zero-padded.
    return startA.compareTo(endB) < 0 && startB.compareTo(endA) < 0;
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return names[weekday - 1];
  }

  Future<List<BookingModel>> fetchMyBookings(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('book_date', ascending: false);

    return (response as List)
        .map((row) => BookingModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel?> fetchBookingById(String bookingId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();

    if (response == null) return null;
    return BookingModel.fromJson(response);
  }

  Future<List<BookingModel>> fetchAllBookings({BookingStatus? statusFilter}) async {
    var query = _client.from(_table).select();

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.value);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((row) => BookingModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _client
        .from(_table)
        .insert(booking.toInsertJson())
        .select()
        .single();

    return BookingModel.fromJson(response);
  }

  Future<BookingModel> cancelBooking(String bookingId) async {
    final response = await _client
        .from(_table)
        .update({'status': BookingStatus.cancelled.value})
        .eq('booking_id', bookingId)
        .select()
        .single();

    return BookingModel.fromJson(response);
  }

  Future<BookingModel> approveBooking(String bookingId) async {
    final response = await _client
        .from(_table)
        .update({'status': BookingStatus.approved.value})
        .eq('booking_id', bookingId)
        .select()
        .single();

    return BookingModel.fromJson(response);
  }

  Future<BookingModel> rejectBooking(String bookingId, {String? reason}) async {
    final response = await _client
        .from(_table)
        .update({
          'status': BookingStatus.rejected.value,
          'reason': reason,
        })
        .eq('booking_id', bookingId)
        .select()
        .single();

    return BookingModel.fromJson(response);
  }
}