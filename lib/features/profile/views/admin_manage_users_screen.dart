import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TemporaryLinkedScreen(
      title: 'User Profiles',
      pageName: 'User Profiles',
    );
  }
}
