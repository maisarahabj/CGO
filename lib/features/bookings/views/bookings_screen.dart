import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_assets.dart';
import '../controllers/booking_controller.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';
import 'create_booking_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return ChangeNotifierProvider(
      create: (_) =>
          BookingController(BookingService(Supabase.instance.client), userId),
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
      context.read<BookingController>().loadBookings();
    });
  }

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
              success
                  ? 'Booking cancelled.'
                  : controller.error ?? 'Could not cancel booking.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.white.withValues(alpha: 0.68)),
          SafeArea(
            child: Consumer<BookingController>(
              builder: (context, controller, _) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: controller.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : controller.error != null
                          ? Center(child: Text(controller.error!))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                32,
                              ),
                              children: [
                                _NavPill(
                                  label: 'Book a Room',
                                  onTap: () {
                                    final bookingController = context
                                        .read<BookingController>();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ChangeNotifierProvider.value(
                                              value: bookingController,
                                              child:
                                                  const CreateBookingScreen(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _SectionPanel(
                                  title: 'Your Bookings',
                                  expanded: _bookingsExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _bookingsExpanded = !_bookingsExpanded;
                                    });
                                  },
                                  child: controller.activeBookings.isEmpty
                                      ? const _EmptyRow(
                                          message: 'No active bookings yet.',
                                        )
                                      : Column(
                                          children: controller.activeBookings
                                              .map(
                                                (b) => BookingCard(
                                                  booking: b,
                                                  roomLabel: controller
                                                      .roomLabelFor(
                                                        b.roomNodeId,
                                                      ),
                                                  onCancel: () =>
                                                      _confirmCancel(
                                                        context,
                                                        controller,
                                                        b.bookingId,
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                _SectionPanel(
                                  title: 'Booking History',
                                  expanded: _historyExpanded,
                                  onToggle: () {
                                    setState(() {
                                      _historyExpanded = !_historyExpanded;
                                    });
                                  },
                                  child: controller.historyBookings.isEmpty
                                      ? const _EmptyRow(
                                          message: 'No past bookings yet.',
                                        )
                                      : Column(
                                          children: controller.historyBookings
                                              .map(
                                                (b) => BookingCard(
                                                  booking: b,
                                                  roomLabel: controller
                                                      .roomLabelFor(
                                                        b.roomNodeId,
                                                      ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                _NavPill(
                                  label: 'How do I book a room?',
                                  onTap: () {},
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.92),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  icon: SvgPicture.asset(
                    AppAssets.backButton,
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    height: 1.17,
                  ),
                  children: [
                    TextSpan(
                      text: 'Campus',
                      style: TextStyle(color: Color(0xFF38358E)),
                    ),
                    TextSpan(
                      text: 'GO',
                      style: TextStyle(color: Color(0xFFFF0000)),
                    ),
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

class _NavPill extends StatelessWidget {
  const _NavPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
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
            SvgPicture.asset(AppAssets.moreRightArrow, width: 18, height: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
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
                SvgPicture.asset(
                  expanded ? AppAssets.moreDownArrow : AppAssets.moreRightArrow,
                  width: 18,
                  height: 18,
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

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}
