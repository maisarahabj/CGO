import 'package:flutter/material.dart';

import 'home_screen.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      accessMode: HomeAccessMode.guest,
      onSessionAction: () async {
        await Navigator.of(context).maybePop();
      },
    );
  }
}
