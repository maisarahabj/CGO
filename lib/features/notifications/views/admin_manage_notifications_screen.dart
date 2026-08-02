import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';

class AdminManageNotificationsScreen extends StatelessWidget {
  const AdminManageNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TemporaryLinkedScreen(
      title: 'Admin Notifications',
      pageName: 'Admin Notifications',
    );
  }
}
