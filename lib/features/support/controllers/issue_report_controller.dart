import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/issue_report_model.dart';
import '../services/issue_report_service.dart';

/// Holds the current user's issue report list + loading/error state.
/// Mirrors BookingController's pattern.
class IssueReportController extends ChangeNotifier {
  final IssueReportService _service;
  final String _userId;

  IssueReportController(this._service, this._userId);

  List<IssueReportModel> _reports = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  List<IssueReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  List<IssueReportModel> get activeReports =>
      _reports.where((r) => r.status.isActive).toList();
  List<IssueReportModel> get historyReports =>
      _reports.where((r) => !r.status.isActive).toList();

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _service.fetchMyReports(_userId);
    } catch (e) {
      _error = 'Could not load your reports. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a new report. If attachmentBytes is provided, uploads it
  /// first and links the resulting URL; otherwise submits without one.
  Future<bool> submitReport({
    required String category,
    required String description,
    Uint8List? attachmentBytes,
    String? attachmentExtension,
  }) async {
    _error = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      String? attachmentUrl;
      if (attachmentBytes != null && attachmentExtension != null) {
        attachmentUrl = await _service.uploadAttachment(
          userId: _userId,
          fileBytes: attachmentBytes,
          extension: attachmentExtension,
        );
      }

      final created = await _service.createReport(
        userId: _userId,
        category: category,
        description: description,
        attachmentUrl: attachmentUrl,
      );
      _reports = [created, ..._reports];
      return true;
    } catch (e) {
      _error = 'Could not submit your report. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
