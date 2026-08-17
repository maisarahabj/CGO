import 'package:flutter/material.dart';

class UnreadNotificationBadge extends StatelessWidget {
  const UnreadNotificationBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 27,
      height: 27,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFFE32636),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            count > 99 ? '99' : count.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
