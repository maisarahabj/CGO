import 'package:flutter/material.dart';
import '../models/issue_report_status.dart';

/// Small colored label for an issue report's status, styled consistently
/// with BookingStatusBadge / the pill badges used across the app.
class IssueStatusBadge extends StatelessWidget {
  final IssueReportStatus status;

  const IssueStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case IssueReportStatus.newReport:
        return const Color(0xFF2A77B4);
      case IssueReportStatus.inReview:
        return const Color(0xFF767676);
      case IssueReportStatus.resolved:
        return const Color(0xFF2E9E4F);
      case IssueReportStatus.rejected:
        return const Color(0xFFE51717);
    }
  }

  String get _label {
    switch (status) {
      case IssueReportStatus.newReport:
        return 'NEW';
      case IssueReportStatus.inReview:
        return 'IN REVIEW';
      case IssueReportStatus.resolved:
        return 'RESOLVED';
      case IssueReportStatus.rejected:
        return 'REJECTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(52)),
      child: Text(
        _label,
        style: const TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w800,
          fontSize: 10,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}