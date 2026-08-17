import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/admin_booking_controller.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';
import '../services/booking_service.dart';

/// Admin-only screen: review pending booking requests, approve or reject
/// them (with an optional reason). Filter chips let admin view by status.
/// Styled consistently with the rest of the bookings feature (same blue
/// borders, pill buttons) even though there's no Figma for this screen yet.
///
/// Reachable only for role == UserRole.admin — app_router.dart guards this
/// before the screen is ever built, same as every other admin_* screen, so
/// no auth params are needed in the constructor.
///
/// Wraps its own locally-scoped AdminBookingController (this app doesn't
/// use a global Provider tree — each screen that needs one builds it
/// itself, same pattern as BookingsScreen).
class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminBookingController(BookingService(Supabase.instance.client)),
      child: const _AdminManageBookingsBody(),
    );
  }
}

class _AdminManageBookingsBody extends StatefulWidget {
  const _AdminManageBookingsBody();

  @override
  State<_AdminManageBookingsBody> createState() => _AdminManageBookingsScreenState();
}

class _AdminManageBookingsScreenState extends State<_AdminManageBookingsBody> {
  static const _borderBlue = Color(0xFF2A77B4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBookingController>().loadBookings();
    });
  }

  Future<void> _confirmReject(BuildContext context, BookingModel booking) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Booking'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE51717)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller = context.read<AdminBookingController>();
      final success = await controller.rejectBooking(
        booking.bookingId,
        reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Booking rejected.' : (controller.error ?? 'Failed.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF115388),
        elevation: 0,
      ),
      body: Consumer<AdminBookingController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              _buildFilterChips(controller),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                        ? Center(child: Text(controller.error!))
                        : controller.bookings.isEmpty
                            ? const Center(child: Text('No bookings found.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: controller.bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = controller.bookings[index];
                                  return _AdminBookingCard(
                                    booking: booking,
                                    roomLabel: controller.roomLabelFor(booking.roomNodeId),
                                    onApprove: booking.status == BookingStatus.pending
                                        ? () async {
                                            final success = await controller.approveBooking(booking.bookingId);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(success ? 'Booking approved.' : (controller.error ?? 'Failed.'))),
                                              );
                                            }
                                          }
                                        : null,
                                    onReject: booking.status == BookingStatus.pending
                                        ? () => _confirmReject(context, booking)
                                        : null,
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(AdminBookingController controller) {
    final options = <String, BookingStatus?>{
      'Pending': BookingStatus.pending,
      'Approved': BookingStatus.approved,
      'Rejected': BookingStatus.rejected,
      'Cancelled': BookingStatus.cancelled,
      'All': null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.entries.map((entry) {
            final selected = controller.filter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: selected,
                selectedColor: _borderBlue,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                onSelected: (_) => controller.setFilter(entry.value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String roomLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminBookingCard({
    required this.booking,
    required this.roomLabel,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(booking.bookDate);
    final startStr = booking.bookStartTime.substring(0, 5);
    final endStr = booking.bookEndTime.substring(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFF2A77B4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  roomLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2A77B4)),
                ),
              ),
              _StatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('$dateStr  •  $startStr - $endStr', style: const TextStyle(color: Color(0xFF61727D))),
          const SizedBox(height: 2),
          Text('Session: ${booking.sessionType}', style: const TextStyle(color: Color(0xFF61727D), fontSize: 13)),
          if (booking.additionalInfo != null && booking.additionalInfo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${booking.additionalInfo}', style: const TextStyle(color: Color(0xFF7E7E7E), fontSize: 13)),
          ],
          if (booking.reason != null && booking.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Rejection reason: ${booking.reason}', style: const TextStyle(color: Color(0xFFE51717), fontSize: 13)),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E9E4F)),
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                  ),
                if (onApprove != null && onReject != null) const SizedBox(width: 8),
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE51717)),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFF767676);
      case BookingStatus.approved:
        return const Color(0xFF2E9E4F);
      case BookingStatus.rejected:
        return const Color(0xFFE51717);
      case BookingStatus.cancelled:
        return const Color(0xFF9BA0AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(52)),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}