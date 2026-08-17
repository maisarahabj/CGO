import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';
import '../services/booking_service.dart';

/// Admin-side booking state: all bookings (optionally filtered by status),
/// plus approve/reject actions. Mirrors BookingController's pattern.
class AdminBookingController extends ChangeNotifier {
  final BookingService _service;

  AdminBookingController(this._service);

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;
  BookingStatus? _filter = BookingStatus.pending; // default view: pending requests

  // node_id -> label, same pattern as BookingController, so admin cards
  // can show real room names too.
  Map<String, String> _roomLabels = {};

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BookingStatus? get filter => _filter;

  String roomLabelFor(String roomNodeId) => _roomLabels[roomNodeId] ?? roomNodeId;

  Future<void> _loadRoomLabels() async {
    try {
      final rooms = await _service.fetchClassroomRooms();
      _roomLabels = {for (final room in rooms) room['node_id']!: room['label']!};
    } catch (e) {
      // Non-fatal — cards fall back to raw node id.
    }
  }

  /// Pass null to show all bookings regardless of status.
  Future<void> setFilter(BookingStatus? status) async {
    _filter = status;
    await loadBookings();
  }

  Future<void> loadBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadRoomLabels();
      _bookings = await _service.fetchAllBookings(statusFilter: _filter);
    } catch (e) {
      _error = 'Could not load bookings. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveBooking(String bookingId) async {
    _error = null;
    try {
      await _service.approveBooking(bookingId);
      // Refresh so the row reflects its new status (and disappears from
      // the pending filter if that's the active view).
      await loadBookings();
      return true;
    } catch (e) {
      _error = 'Could not approve this booking. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    _error = null;
    try {
      await _service.rejectBooking(bookingId, reason: reason);
      await loadBookings();
      return true;
    } catch (e) {
      _error = 'Could not reject this booking. Please try again.';
      notifyListeners();
      return false;
    }
  }
}