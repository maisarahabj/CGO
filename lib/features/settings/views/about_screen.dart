import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _InformationPage(
      title: 'About CampusGO',
      children: const [
        Text(
          'CampusGO',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF38358E),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'CampusGO is an indoor campus navigation application designed '
          'to help students, lecturers, staff and visitors find supported '
          'destinations around campus.',
        ),
        SizedBox(height: 18),
        Text(
          'Key Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          '• Indoor navigation and route guidance\n'
          '• QR-supported starting point selection\n'
          '• Timetable-assisted navigation\n'
          '• Room and booking functionality\n'
          '• Accessibility-friendly routes\n'
          '• Notifications and reminders\n'
          '• Issue reporting and support',
        ),
        SizedBox(height: 18),
        Text(
          'CampusGO is developed as an academic project for UNIMY.',
          style: TextStyle(color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _InformationPage extends StatelessWidget {
  const _InformationPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            color: Color(0xFF38358E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            height: 1.55,
            color: Color(0xFF3F3F3F),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
