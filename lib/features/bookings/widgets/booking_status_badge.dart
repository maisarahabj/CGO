import 'package:flutter/material.dart';
import '../models/booking_status.dart';

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.approved:
        return Colors.green;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.approved:
        return 'APPROVED';
      case BookingStatus.rejected:
        return 'REJECTED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}