import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';

class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TemporaryLinkedScreen(
      title: 'Booking Requests',
      pageName: 'Booking Requests',
    );
  }
}
