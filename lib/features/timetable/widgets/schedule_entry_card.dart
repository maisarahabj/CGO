import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../models/timetable_model.dart';

class ScheduleEntryCard extends StatelessWidget {
  const ScheduleEntryCard({
    super.key,
    required this.entry,
    required this.onRemove,
    this.onNavigate,
    this.isOngoing = false,
    this.isBusy = false,
  });

  final TimetableModel entry;

  final Future<void> Function() onRemove;

  final VoidCallback? onNavigate;

  final bool isOngoing;

  final bool isBusy;

  static const Color _blue = Color(0xFF176F9E);

  static const Color _purple = Color(0xFF37258B);

  static const Color _orange = Color(0xFFFF6A00);

  static const Color _softBlue = Color(0xFFEDF6FB);

  @override
  Widget build(BuildContext context) {
    final lecturer = entry.lecturer?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 8, 11),
      decoration: BoxDecoration(
        color: isOngoing ? _softBlue : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: isOngoing ? Border.all(color: _blue, width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roomIllustration(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _text(entry.roomName, 'ROOM').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatTime(entry.startTime)}'
                          ' - '
                          '${_formatTime(entry.endTime)}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0xFF747A82),
                          ),
                        ),
                        if (isOngoing) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC313),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ON-GOING',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _text(
                    entry.subjectName,
                    entry.subjectCode ?? 'Scheduled class',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C434A),
                  ),
                ),
                if (lecturer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 13,
                        color: Color(0xFF959BA2),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lecturer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: Color(0xFF959BA2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onNavigate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: isOngoing
                                ? const LinearGradient(
                                    colors: [_purple, _orange],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            border: isOngoing ? null : Border.all(color: _blue),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppAssets.navPointer,
                                width: 13,
                                height: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Navigate Now',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOngoing ? Colors.white : _blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Remove from My Schedule',
                      onPressed: isBusy
                          ? null
                          : () async {
                              await onRemove();
                            },
                      visualDensity: VisualDensity.compact,
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.bookmark_remove_outlined,
                              size: 19,
                              color: Color(0xFF7C858E),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomIllustration() {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E9D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(AppAssets.destinationClassroom, fit: BoxFit.contain),
    );
  }

  String _text(String? value, String fallback) {
    final text = value?.trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  String _formatTime(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '--:--';
    }

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return text;
  }
}
