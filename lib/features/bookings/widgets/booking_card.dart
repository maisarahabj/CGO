import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.roomLabel,
    this.locationText,
    this.onTap,
    this.onCancel,
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final String roomLabel;
  final String? locationText;

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
            Container(
              width: 60,
              height: 56,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFDAE7FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                AppAssets.destinationClassroom,
                fit: BoxFit.contain,
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
                      Flexible(
                        child: Text(
                          roomLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                            height: 1.08,
                            color: Color(0xFF2A77B4),
                          ),
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
                      Flexible(
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.08,
                            color: Color(0xFF61727D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
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
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Color.fromRGBO(97, 114, 125, 0.53),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            locationText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              height: 1.18,
                              color: Color.fromRGBO(97, 114, 125, 0.67),
                            ),
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
  const _CancelPill({required this.onTap});

  final VoidCallback onTap;

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
