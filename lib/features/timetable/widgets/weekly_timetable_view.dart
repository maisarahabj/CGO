import 'package:flutter/material.dart';

import '../models/timetable_model.dart';
import 'schedule_entry_card.dart';

class WeeklyTimetableView extends StatelessWidget {
  const WeeklyTimetableView({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.entries,
    required this.currentClass,
    required this.onDaySelected,
    required this.onRemove,
    required this.isBusy,
    this.onNavigate,
  });

  final List<String> days;

  final String selectedDay;

  final List<TimetableModel> entries;

  final TimetableModel? currentClass;

  final ValueChanged<String> onDaySelected;

  final Future<void> Function(TimetableModel entry) onRemove;

  final bool Function(int timetableId) isBusy;

  final ValueChanged<TimetableModel>? onNavigate;

  static const Color _blue = Color(0xFF176F9E);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _daySelector(),
        const SizedBox(height: 21),
        const Text(
          'Weekly Timetable',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 42, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 44,
                  color: Color(0xFF9AA3AA),
                ),
                SizedBox(height: 12),
                Text(
                  'You have no classes saved for this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF7A8289),
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: ScheduleEntryCard(
                key: ValueKey('saved-${entry.timetableId}'),
                entry: entry,
                isOngoing: currentClass?.timetableId == entry.timetableId,
                isBusy: isBusy(entry.timetableId),
                onNavigate: onNavigate == null
                    ? null
                    : () {
                        final callback = onNavigate;

                        if (callback != null) {
                          callback(entry);
                        }
                      },
                onRemove: () => onRemove(entry),
              ),
            ),
          ),
      ],
    );
  }

  Widget _daySelector() {
    return Container(
      height: 61,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: days.map((day) {
          final selected = day == selectedDay;

          return Expanded(
            child: InkWell(
              onTap: () => onDaySelected(day),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortDay(day),
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 30 : 0,
                    height: 2,
                    color: _blue,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _shortDay(String day) {
    switch (day) {
      case 'Monday':
        return 'Mon';

      case 'Tuesday':
        return 'Tue';

      case 'Wednesday':
        return 'Wed';

      case 'Thursday':
        return 'Thu';

      case 'Friday':
        return 'Fri';

      default:
        return day;
    }
  }
}
