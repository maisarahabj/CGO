import 'package:flutter/material.dart';

class GuestAccessButton extends StatelessWidget {
  const GuestAccessButton({
    required this.onPressed,
    this.isEnabled = true,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4A057E),
          side: const BorderSide(
            color: Color(0xFF4A057E),
            width: 2.4,
          ),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Start as Guest'),
      ),
    );
  }
}
