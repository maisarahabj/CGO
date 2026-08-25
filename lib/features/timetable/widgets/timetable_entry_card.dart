import 'package:flutter/material.dart';

import '../models/timetable_model.dart';

class TimetableEntryCard extends StatelessWidget {
  const TimetableEntryCard({
    super.key,
    required this.entry,
    this.isOngoing = false,
    this.showLecturer = true,
    this.onTap,
  });

  final TimetableModel entry;
  final bool isOngoing;
  final bool showLecturer;
  final VoidCallback? onTap;

  static const Color _blue = Color(0xFF267BAD);
  static const Color _lightBlue = Color(0xFFEDF5FA);
  static const Color _darkText = Color(0xFF272727);

  @override
  Widget build(BuildContext context) {
    final lecturer = entry.lecturer?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _blue, width: 1),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _text(entry.subjectName, 'Scheduled Class'),
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _darkText,
                            ),
                          ),
                        ),
                        if (isOngoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'On-going',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (showLecturer && lecturer.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 15,
                            color: Color(0xFF68727D),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              lecturer,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: Color(0xFF68727D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _text(String? value, String fallback) {
    final text = value?.trim() ?? '';

    return text.isEmpty ? fallback : text;
  }
}
