import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

/// Matches Figma "17 Users book a room" exactly: room name (Roboto
/// Condensed 500 26px #2A77B4), time (Roboto Condensed 500 20px #959BB1),
/// date (Raleway 700 17px #61727D), location (Raleway 700 11px
/// rgba(97,114,125,0.67)), CANCEL pill (#E51717).
///
/// No status badge — the Figma design doesn't show one anywhere, including
/// in Booking History. Active vs. history is distinguished purely by
/// whether the Cancel button is present.
class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final String roomLabel;
  final String? locationText;

  const BookingCard({
    super.key,
    required this.booking,
    required this.roomLabel,
    this.locationText,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMM').format(booking.bookDate);
    final timeParts = booking.bookStartTime.split(':');
    final timeStr = '${timeParts[0]}:${timeParts[1]}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 56,
                color: const Color(0xFFDAE7FF),
                child: const Icon(Icons.meeting_room, color: Color(0xFF2A77B4), size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        roomLabel.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Roboto Condensed',
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          height: 1.08,
                          color: Color(0xFF2A77B4),
                        ),
                      ),
                      if (onCancel != null) ...[
                        const SizedBox(width: 8),
                        _CancelPill(onTap: onCancel!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.08,
                          color: Color(0xFF61727D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Roboto Condensed',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.08,
                          color: Color(0xFF959BB1),
                        ),
                      ),
                    ],
                  ),
                  if (locationText != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color.fromRGBO(97, 114, 125, 0.53)),
                        const SizedBox(width: 3),
                        Text(
                          locationText!,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            height: 1.18,
                            color: Color.fromRGBO(97, 114, 125, 0.67),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelPill extends StatelessWidget {
  final VoidCallback onTap;
  const _CancelPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(52),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE51717),
          borderRadius: BorderRadius.circular(52),
        ),
        child: const Text(
          'CANCEL',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            fontSize: 10,
            height: 1.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}