enum IssueReportStatus {
  newReport('new'),
  inReview('in_review'),
  resolved('resolved'),
  rejected('rejected');

  final String value;
  const IssueReportStatus(this.value);

  static IssueReportStatus fromValue(String value) {
    return IssueReportStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => throw ArgumentError('Unknown issue report status: $value'),
    );
  }

  bool get isActive => this == IssueReportStatus.newReport || this == IssueReportStatus.inReview;
}

class IssueReportCategory {
  static const incorrectRoomOrFacility = 'Incorrect room or facility information';
  static const blockedCorridorOrRoute = 'Blocked corridor or route';
  static const qrCheckpointIssue = 'QR checkpoint issue';
  static const navigationIssue = 'Navigation issue';
  static const suggestion = 'Suggestion';

  static const all = [
    incorrectRoomOrFacility,
    blockedCorridorOrRoute,
    qrCheckpointIssue,
    navigationIssue,
    suggestion,
  ];
}