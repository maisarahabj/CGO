import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
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

  static const Color _dayBlue = Color(0xFF185C92);
  static const Color _headingBlue = Color(0xFF115388);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          top: 31,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x240C3450),
                  blurRadius: 18,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(42),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.white),
                  Opacity(
                    opacity: 0.07,
                    child: Image.asset(
                      AppAssets.loginBackground,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xDFFFFFFF), Color(0xF5FFFFFF)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _daySelector(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Weekly Timetable',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _headingBlue,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
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
                        fontFamily: 'RobotoCondensed',
                        fontFamilyFallback: ['Roboto'],
                        fontSize: 15,
                        color: Color(0xFF7A8289),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 5,
                  ),
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
            const SizedBox(height: 18),
          ],
        ),
      ],
    );
  }

  Widget _daySelector() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
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
                      fontFamily: 'RobotoFlex',
                      fontFamilyFallback: ['RobotoCondensed', 'Roboto'],
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _dayBlue,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 37 : 0,
                    height: 2.5,
                    color: _dayBlue,
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
