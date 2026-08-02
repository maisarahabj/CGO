import 'package:flutter/material.dart';

/// Temporary destination used while a feature branch builds the real UI.
class TemporaryLinkedScreen extends StatelessWidget {
  const TemporaryLinkedScreen({
    required this.title,
    required this.pageName,
    super.key,
  });

  final String title;
  final String pageName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Remove this text later. This text shows that the linking works. '
            'The $pageName page interface will go here. - Mai',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
