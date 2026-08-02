import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';

class AdminManageIssueReportsScreen extends StatelessWidget {
  const AdminManageIssueReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TemporaryLinkedScreen(
      title: 'Issue Reports',
      pageName: 'Issue Reports',
    );
  }
}
