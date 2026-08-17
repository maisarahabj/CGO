import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/issue_report_model.dart';
import '../models/issue_report_status.dart';

/// Supabase operations for `issue_reports` and its attachment uploads.
///
/// RLS (confirmed live):
///  - INSERT: reporters can create their own reports (user_id = auth.uid())
///  - SELECT: own reports, or all if admin
///  - UPDATE: admins only (status/admin_notes)
///
/// Storage policy on `issue-report-attachments` bucket requires the file
/// path's first folder segment to equal auth.uid(), and the extension to
/// be one of jpg/jpeg/png/webp/heic/heif. uploadAttachment() builds that
/// path automatically — callers just pass the raw file bytes.
class IssueReportService {
  final SupabaseClient _client;

  IssueReportService(this._client);

  static const String _table = 'issue_reports';
  static const String _bucket = 'issue-report-attachments';

  Future<List<IssueReportModel>> fetchMyReports(String userId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => IssueReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<IssueReportModel?> fetchReportById(String reportId) async {
    final response =
        await _client.from(_table).select().eq('report_id', reportId).maybeSingle();

    if (response == null) return null;
    return IssueReportModel.fromJson(response);
  }

  /// Admin: fetch all reports, optionally filtered by status.
  Future<List<IssueReportModel>> fetchAllReports({IssueReportStatus? statusFilter}) async {
    var query = _client.from(_table).select();

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.value);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((row) => IssueReportModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Uploads a screenshot to the issue-report-attachments bucket under
  /// {userId}/{generatedFilename}.{ext}, matching the storage policy's
  /// required path shape. Returns the public URL to store in
  /// attachment_url. extension should be one of: jpg, jpeg, png, webp,
  /// heic, heif (no leading dot).
  Future<String> uploadAttachment({
    required String userId,
    required List<int> fileBytes,
    required String extension,
  }) async {
    final fileName = '${const Uuid().v4()}.$extension';
    final path = '$userId/$fileName';

    await _client.storage.from(_bucket).uploadBinary(path, Uint8ListFromList(fileBytes));

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// Create a new issue report. report_id is generated client-side since
  /// the column is NOT NULL text, not an auto-generated column.
  /// If attachmentUrl is provided, it's included directly; otherwise call
  /// uploadAttachment() first and pass the result in here.
  Future<IssueReportModel> createReport({
    required String userId,
    required String category,
    required String description,
    String? attachmentUrl,
  }) async {
    final report = IssueReportModel(
      reportId: const Uuid().v4(),
      userId: userId,
      category: category,
      description: description,
      attachmentUrl: attachmentUrl,
      status: IssueReportStatus.newReport,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final response = await _client.from(_table).insert(report.toInsertJson()).select().single();
    return IssueReportModel.fromJson(response);
  }

  /// Admin: update status and/or notes on a report.
  Future<IssueReportModel> updateReportStatus(
    String reportId, {
    required IssueReportStatus status,
    String? adminNotes,
  }) async {
    final response = await _client
        .from(_table)
        .update({
          'status': status.value,
          if (adminNotes != null) 'admin_notes': adminNotes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('report_id', reportId)
        .select()
        .single();

    return IssueReportModel.fromJson(response);
  }
}

/// Small helper since Supabase storage's uploadBinary expects Uint8List.
Uint8List Uint8ListFromList(List<int> bytes) {
  if (bytes is Uint8List) return bytes;
  return Uint8List.fromList(bytes);
}