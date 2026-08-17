import 'package:flutter/foundation.dart';
import '../models/issue_report_model.dart';
import '../models/issue_report_status.dart';
import '../services/issue_report_service.dart';


/// Admin-side issue report state: all reports (optionally filtered by
/// status), plus updateStatus for review/resolution. Mirrors
/// AdminBookingController's pattern.
class AdminIssueReportController extends ChangeNotifier {
  final IssueReportService _service;

  AdminIssueReportController(this._service);

  List<IssueReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;
  IssueReportStatus? _filter = IssueReportStatus.newReport;

  List<IssueReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  IssueReportStatus? get filter => _filter;

  Future<void> setFilter(IssueReportStatus? status) async {
    _filter = status;
    await loadReports();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _service.fetchAllReports(statusFilter: _filter);
    } catch (e) {
      _error = 'Could not load reports. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(
    String reportId, {
    required IssueReportStatus status,
    String? adminNotes,
  }) async {
    _error = null;
    try {
      await _service.updateReportStatus(reportId, status: status, adminNotes: adminNotes);
      await loadReports();
      return true;
    } catch (e) {
      _error = 'Could not update this report. Please try again.';
      notifyListeners();
      return false;
    }
  }
}