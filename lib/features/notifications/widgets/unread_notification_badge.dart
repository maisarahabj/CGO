import 'package:flutter/material.dart';

class UnreadNotificationBadge extends StatelessWidget {
  const UnreadNotificationBadge({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final displayCount =
        count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE32636),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayCount,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}