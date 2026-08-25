class OngoingClassModel {
  const OngoingClassModel({
    required this.timetableId,
    required this.roomNodeId,
    required this.roomName,
    required this.subjectName,
    required this.startMinutes,
    required this.endMinutes,
    required this.floorLabel,
    this.dayLabel = '',
    this.buildingLabel = 'Menara BAC',
    this.estimatedWalkMinutes = 1,
  });

  final String timetableId;
  final String roomNodeId;
  final String roomName;
  final String subjectName;
  final int startMinutes;
  final int endMinutes;
  final String floorLabel;
  final String dayLabel;
  final String buildingLabel;
  final int estimatedWalkMinutes;

  String get timeRange =>
      '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}';

  /// Used by the home-page "Next Classes" cards so a class from another
  /// weekday is not mistaken for a class happening later today.
  String get scheduleTimeLabel {
    final cleanDay = dayLabel.trim();

    if (cleanDay.isEmpty) {
      return timeRange;
    }

    return '$cleanDay · $timeRange';
  }

  static String _formatMinutes(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
