import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';

class BookingService {
  final SupabaseClient _client;

  BookingService(this._client);

  static const String _table = 'bookings';
  static const String _nodesTable = 'nodes';

  /// Fetch classroom nodes for the room-selection dropdown.
  /// Returns each node's id and label. Read-only lookup into the
  /// `nodes` table (owned by the navigation feature) — if MAII later
  /// builds a proper NavigationService with this same query, this
  /// method can be removed in favor of that one.
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