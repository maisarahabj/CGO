import 'package:flutter/material.dart';

import '../../../shared/widgets/temporary_linked_screen.dart';

class AdminManageNavigationScreen extends StatelessWidget {
  const AdminManageNavigationScreen({required this.pageTitle, super.key});

  final String pageTitle;

  @override
  Widget build(BuildContext context) {
    return TemporaryLinkedScreen(title: pageTitle, pageName: pageTitle);
  }
}
