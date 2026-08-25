import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/booking_controller.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';
import 'create_booking_screen.dart';

/// Matches Figma "17 Users book a room" screen.
///
/// Reachable only for role == UserRole.user (see app_router.dart).
///
/// This screen creates its own locally-scoped BookingController using
/// the currently authenticated Supabase user.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return ChangeNotifierProvider(
      create: (_) => BookingController(
        BookingService(Supabase.instance.client),
        userId,
      ),
      child: const _BookingsScreenBody(),
    );
  }
}

class _BookingsScreenBody extends StatefulWidget {
  const _BookingsScreenBody();

  @override
  State<_BookingsScreenBody> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<_BookingsScreenBody> {
  bool _bookingsExpanded = true;
  bool _historyExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookingController>().loadBookings();
      }
    });
  }

  // --------------------------------------------------------------------------
  // CANCEL BOOKING
  // --------------------------------------------------------------------------

  Future<void> _confirmCancel(
    BuildContext context,
    BookingController controller,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, Keep It'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.cancelBooking(bookingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Booking cancelled.' : (controller.error ?? 'Could not cancel booking.'),
            ),
          ),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // HOW TO BOOK DIALOG
  // --------------------------------------------------------------------------

  void _showBookingInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF2A77B4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A77B4)),
                        ),
                        child: const Icon(Icons.help_outline, color: Color(0xFF2A77B4)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'How do I book a room?',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            color: Color(0xFF115388),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Color(0xFF777777)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Follow these steps to submit a room booking request:',
                    style: TextStyle(fontFamily: 'Roboto Flex', fontSize: 15, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 18),
                  const _InstructionStep(
                    number: '1',
                    icon: Icons.calendar_today_outlined,
                    title: 'Choose a date',
                    description: 'Select the date on which you need the room.',
                  ),
                  const SizedBox(height: 14),
                  const _InstructionStep(
                    number: '2',
                    icon: Icons.schedule,
                    title: 'Choose a time',
                    description: 'Select the start and end time for your booking.',
                  ),
                  const SizedBox(height: 14),
                  const _InstructionStep(
                    number: '3',
                    icon: Icons.menu_book_outlined,
                    title: 'Select an available room',
                    description:
                        'Choose a room from the dropdown. Only rooms free '
                        'for the selected date and time will be shown.',
                  ),
                  const SizedBox(height: 14),
                  const _InstructionStep(
                    number: '4',
                    icon: Icons.meeting_room_outlined,
                    title: 'Check the room',
                    description: 'Review the room details before you submit the request.',
                  ),
                  const SizedBox(height: 14),
                  const _InstructionStep(
                    number: '5',
                    icon: Icons.send_outlined,
                    title: 'Submit your request',
                    description:
                        'Add any additional information if needed, then '
                        'submit your booking request for admin approval.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2A77B4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Color(0xFF2A77B4)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your request is not automatically approved. '
                            'An administrator must review and approve the '
                            'booking before the room is confirmed.',
                            style: TextStyle(
                              fontFamily: 'Roboto Condensed',
                              fontSize: 14,
                              height: 1.35,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A77B4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<BookingController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(controller.error!, textAlign: TextAlign.center),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              children: [
                                _NavPill(
                                  label: 'Book a Room',
                                  onTap: () {
                                    // Pass the SAME already-created controller instance
                                    // into the pushed route. A plain Navigator.push does
                                    // not inherit this screen's provider scope (pushed
                                    // routes attach to the app's root Navigator, not as
                                    // a widget-tree child of this screen), so without
                                    // this CreateBookingScreen would throw
                                    // "Could not find the correct Provider<BookingController>".
                                    final bookingController = context.read<BookingController>();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider.value(
                                          value: bookingController,
                                          child: const CreateBookingScreen(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _SectionPanel(
                                  title: 'Your Bookings',
                                  expanded: _bookingsExpanded,
                                  onToggle: () => setState(() => _bookingsExpanded = !_bookingsExpanded),
                                  child: controller.activeBookings.isEmpty
                                      ? const _EmptyRow(message: 'No active bookings yet.')
                                      : Column(
                                          children: controller.activeBookings
                                              .map(
                                                (booking) => BookingCard(
                                                  booking: booking,
                                                  roomLabel: controller.roomLabelFor(booking.roomNodeId),
                                                  onCancel: () => _confirmCancel(context, controller, booking.bookingId),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                _SectionPanel(
                                  title: 'Booking History',
                                  expanded: _historyExpanded,
                                  onToggle: () => setState(() => _historyExpanded = !_historyExpanded),
                                  child: controller.historyBookings.isEmpty
                                      ? const _EmptyRow(message: 'No past bookings yet.')
                                      : Column(
                                          children: controller.historyBookings
                                              .map(
                                                (booking) => BookingCard(
                                                  booking: booking,
                                                  roomLabel: controller.roomLabelFor(booking.roomNodeId),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                _NavPill(
                                  label: 'How do I book a room?',
                                  onTap: () => _showBookingInstructions(context),
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

  // --------------------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF185C92)),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.17,
                  ),
                  children: [
                    TextSpan(text: 'Campus', style: TextStyle(color: Color(0xFF38358E))),
                    TextSpan(text: 'GO', style: TextStyle(color: Color(0xFFE51717))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Book a Room',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.08,
              color: Color(0xFF115388),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1.2,
            color: const Color(0xFF2A77B4),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NAVIGATION PILL
// ============================================================================

class _NavPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(color: const Color(0xFF2A77B4)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1.08,
                  color: Color(0xFF606060),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF868DA6)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION PANEL
// ============================================================================

class _SectionPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  const _SectionPanel({
    required this.title,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFF2A77B4)),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.08,
                      color: Color(0xFF606060),
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF868DA6),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF2A77B4), thickness: 1, height: 1),
            const SizedBox(height: 4),
            child,
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY ROW
// ============================================================================

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

// ============================================================================
// INSTRUCTION STEP
// ============================================================================

class _InstructionStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 34,
          width: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF2A77B4), shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2A77B4)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2A77B4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto Flex',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Roboto Condensed',
                  fontSize: 14,
                  height: 1.3,
                  color: Color(0xFF747474),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
