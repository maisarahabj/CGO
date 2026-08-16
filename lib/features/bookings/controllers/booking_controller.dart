import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';
import '../services/booking_service.dart';

/// Holds the current user's booking list + loading/error state.
/// Screens should read this via Provider, never call BookingService directly.
class BookingController extends ChangeNotifier {
  final BookingService _service;
  final String _userId;

  BookingController(this._service, this._userId);

  /// Exposed so screens can call read-only lookups (e.g. fetchClassroomRooms)
  /// without needing their own separate BookingService instance.
  BookingService get service => _service;

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  // node_id -> label, so cards can show "Python" instead of a raw node id.
  Map<String, String> _roomLabels = {};

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BookingModel> get activeBookings =>
      _bookings.where((b) => b.status.isActive).toList();

  List<BookingModel> get historyBookings =>
      _bookings.where((b) => !b.status.isActive).toList();

  /// Returns the human-readable room label for a booking's roomNodeId.
  /// Falls back to the raw id if the room list hasn't loaded yet or the
  /// room was removed/renamed since the booking was made.
  String roomLabelFor(String roomNodeId) => _roomLabels[roomNodeId] ?? roomNodeId;

  Future<void> _loadRoomLabels() async {
    try {
      final rooms = await _service.fetchClassroomRooms();
      _roomLabels = {
        for (final room in rooms) room['node_id']!: room['label']!,
      };
    } catch (e) {
      // Non-fatal — cards just fall back to showing the raw node id.
    }
  }

  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadRoomLabels();
      _bookings = await _service.fetchMyBookings(_userId);
    } catch (e) {
      _error = 'Could not load your bookings. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking(BookingModel booking) async {
    _error = null;
    try {
      final bookingWithUser = booking.copyWith(userId: _userId);
      final created = await _service.createBooking(bookingWithUser);
      _bookings = [created, ..._bookings];
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Could not submit your booking request. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _error = null;
    try {
      final updated = await _service.cancelBooking(bookingId);
      final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Could not cancel this booking. Please try again.';
      notifyListeners();
      return false;
    }
  }
}