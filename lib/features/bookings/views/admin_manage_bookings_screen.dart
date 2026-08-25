import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/admin_booking_controller.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';
import '../services/booking_service.dart';

/// Admin-only screen: review pending booking requests, approve or reject
/// them (with a required, categorized reason). Filter chips let admin view
/// by status.
///
/// UI styling follows the same visual style as AdminManageIssueReportsScreen.
/// Booking/controller/backend logic is unchanged.
class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminBookingController(
        BookingService(Supabase.instance.client),
      ),
      child: const _AdminManageBookingsBody(),
    );
  }
}

class _AdminManageBookingsBody extends StatefulWidget {
  const _AdminManageBookingsBody();

  @override
  State<_AdminManageBookingsBody> createState() =>
      _AdminManageBookingsScreenState();
}

class _AdminManageBookingsScreenState
    extends State<_AdminManageBookingsBody> {
  static const _borderBlue = Color(0xFF2A77B4);
  static const _valueGrey = Color(0xFF424242);

  static const _rejectReasonOptions = [
    
    'Insufficient details provided',
    'Policy violation',
    'Room unavailable for maintenance',
    'Duplicate request',
     'Room already booked for this time slot',
    'Conflicts with a scheduled class',
    'Room capacity insufficient for stated purpose',
    'Booking request submitted too close to start time',
    'Room reserved for maintenance or cleaning',
    'Session type does not match room facilities',
    'Missing or unclear purpose in additional info',
    'Exceeds maximum booking duration allowed',
    'Duplicate booking request from same user',
    'Room temporarily closed or under repair',
    'Requested outside of permitted booking hours',
    'Other',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBookingController>().loadBookings();
    });
  }

  String? _validateRejectReason(String reason) {
    final trimmed = reason.trim();

    if (trimmed.isEmpty) {
      return 'Please explain why this booking is being rejected.';
    }

    final wordCount =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount < 10) {
      return 'Please write at least 10 words explaining the reason.';
    }

    return null;
  }

  Future<void> _confirmReject(
    BuildContext context,
    BookingModel booking,
  ) async {
    final reasonController = TextEditingController();
    String? selectedCategory;
    String? reasonError;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 6,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                      children: [
                        TextSpan(
                          text: 'Campus',
                          style: TextStyle(color: Color(0xFF38358E)),
                        ),
                        TextSpan(
                          text: 'GO',
                          style: TextStyle(color: Color(0xFFE51717)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Reject Booking',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF115388),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1.2, color: _borderBlue),
                const SizedBox(height: 18),

                const Text(
                  'Reason category',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _borderBlue),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.11),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      hint: const Text(
                        'Select a reason',
                        style: TextStyle(
                          fontFamily: 'Roboto Flex',
                          color: Color(0xFF919191),
                        ),
                      ),
                      items: _rejectReasonOptions
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto Flex',
                                    color: _valueGrey,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() {
                          selectedCategory = value;
                          if (value != null &&
                              value != 'Other' &&
                              reasonController.text.trim().isEmpty) {
                            reasonController.text = '$value. ';
                            reasonController.selection =
                                TextSelection.collapsed(
                              offset: reasonController.text.length,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Explanation',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Required — at least 10 words. This will be shown to the requester.',
                  style: TextStyle(
                    fontFamily: 'Roboto Condensed',
                    fontSize: 12,
                    color: Color(0xFF747474),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FF),
                    border: Border.all(
                      color: reasonError != null ? Colors.red : _borderBlue,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'Roboto Condensed',
                      fontSize: 15,
                      color: _valueGrey,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (_) {
                      if (reasonError != null) {
                        setSheetState(() => reasonError = null);
                      }
                    },
                  ),
                ),
                if (reasonError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    reasonError!,
                    style: const TextStyle(
                      fontFamily: 'Roboto Condensed',
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _borderBlue),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            color: _borderBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final error =
                              _validateRejectReason(reasonController.text);
                          if (error != null) {
                            setSheetState(() => reasonError = error);
                            return;
                          }
                          Navigator.pop(sheetContext, true);
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE51717),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller = context.read<AdminBookingController>();

      final success = await controller.rejectBooking(
        booking.bookingId,
        reason: reasonController.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Booking rejected.' : (controller.error ?? 'Failed.'),
            ),
          ),
        );
      }
    }

    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AdminBookingController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : controller.error != null
                          ? Center(
                              child: Text(controller.error!),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                32,
                              ),
                              children: [
                                _buildFilterChips(controller),

                                const SizedBox(height: 16),

                                if (controller.bookings.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No bookings found.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...controller.bookings.map(
                                    (booking) => _AdminBookingCard(
                                      booking: booking,
                                      roomLabel:
                                          controller.roomLabelFor(
                                        booking.roomNodeId,
                                      ),
                                      onApprove:
                                          booking.status ==
                                                  BookingStatus.pending
                                              ? () async {
                                                  final success =
                                                      await controller
                                                          .approveBooking(
                                                    booking.bookingId,
                                                  );

                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          success
                                                              ? 'Booking approved.'
                                                              : (controller
                                                                      .error ??
                                                                  'Failed.'),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              : null,
                                      onReject:
                                          booking.status ==
                                                  BookingStatus.pending
                                              ? () => _confirmReject(
                                                    context,
                                                    booking,
                                                  )
                                              : null,
                                    ),
                                  ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF185C92),
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                  children: [
                    TextSpan(
                      text: 'Campus',
                      style: TextStyle(
                        color: Color(0xFF38358E),
                      ),
                    ),
                    TextSpan(
                      text: 'GO',
                      style: TextStyle(
                        color: Color(0xFFE51717),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          const Text(
            'Manage Bookings',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF115388),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1.2,
            color: _borderBlue,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FILTER CHIPS
  // ==========================================================================

  Widget _buildFilterChips(AdminBookingController controller) {
    final options = <String, BookingStatus?>{
      'Pending': BookingStatus.pending,
      'Approved': BookingStatus.approved,
      'Rejected': BookingStatus.rejected,
      'Cancelled': BookingStatus.cancelled,
      'All': null,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final selected = controller.filter == entry.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => controller.setFilter(entry.value),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _borderBlue
                      : Colors.white,
                  border: Border.all(
                    color: _borderBlue,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: selected
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected
                        ? Colors.white
                        : _valueGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// ADMIN BOOKING CARD
// ============================================================================

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
    final dateStr =
        DateFormat('d MMM yyyy').format(booking.bookDate);

    final startStr =
        booking.bookStartTime.substring(0, 5);

    final endStr =
        booking.bookEndTime.substring(0, 5);

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(
            color: const Color(0xFF2A77B4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------------------
            // ROOM + STATUS
            // --------------------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Text(
                    roomLabel,
                    style: const TextStyle(
                      fontFamily: 'Roboto Flex',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF2A77B4),
                    ),
                  ),
                ),

                _StatusChip(
                  status: booking.status,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------------------
            // DATE
            // --------------------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF2A77B4),
                ),
                const SizedBox(width: 7),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Roboto Flex',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // --------------------------------------------------------------
            // TIME
            // --------------------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: Color(0xFF2A77B4),
                ),
                const SizedBox(width: 7),
                Text(
                  '$startStr - $endStr',
                  style: const TextStyle(
                    fontFamily: 'Roboto Flex',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // --------------------------------------------------------------
            // SESSION TYPE
            // --------------------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 16,
                  color: Color(0xFF2A77B4),
                ),
                const SizedBox(width: 7),
                Text(
                  booking.sessionType,
                  style: const TextStyle(
                    fontFamily: 'Roboto Flex',
                    fontSize: 14,
                    color: Color(0xFF61727D),
                  ),
                ),
              ],
            ),

            // --------------------------------------------------------------
            // ADDITIONAL INFORMATION
            // --------------------------------------------------------------

            if (booking.additionalInfo != null &&
                booking.additionalInfo!.isNotEmpty) ...[
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Note: ${booking.additionalInfo}',
                  style: const TextStyle(
                    fontFamily: 'Roboto Condensed',
                    fontSize: 13,
                    color: Color(0xFF7E7E7E),
                  ),
                ),
              ),
            ],

            // --------------------------------------------------------------
            // REJECTION REASON
            // --------------------------------------------------------------

            if (booking.reason != null &&
                booking.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rejection reason: ${booking.reason}',
                  style: const TextStyle(
                    fontFamily: 'Roboto Condensed',
                    fontSize: 13,
                    color: Color(0xFFE51717),
                  ),
                ),
              ),
            ],

            // --------------------------------------------------------------
            // ACTION BUTTONS
            // --------------------------------------------------------------

            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 14),

              Row(
                children: [
                  if (onApprove != null)
                    Expanded(
                      child: InkWell(
                        onTap: onApprove,
                        borderRadius:
                            BorderRadius.circular(30),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E4F),
                            borderRadius:
                                BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (onApprove != null &&
                      onReject != null)
                    const SizedBox(width: 10),

                  if (onReject != null)
                    Expanded(
                      child: InkWell(
                        onTap: onReject,
                        borderRadius:
                            BorderRadius.circular(30),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE51717),
                            ),
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFFE51717),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS CHIP
// ============================================================================

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({
    required this.status,
  });

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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(52),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Roboto Flex',
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}