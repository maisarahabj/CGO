import 'issue_report_status.dart';

class IssueReportModel {
  final String reportId;
  final String? userId;
  final String category;
  final String description;
  final String? attachmentUrl;
  final IssueReportStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IssueReportModel({
    required this.reportId,
    this.userId,
    required this.category,
    required this.description,
    this.attachmentUrl,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IssueReportModel.fromJson(Map<String, dynamic> json) {
    return IssueReportModel(
      reportId: json['report_id'] as String,
      userId: json['user_id'] as String?,
      category: json['category'] as String,
      description: json['description'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      status: IssueReportStatus.fromValue(json['status'] as String),
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'report_id': reportId,
      'user_id': userId,
      'category': category,
      'description': description,
      'attachment_url': attachmentUrl,
      'status': IssueReportStatus.newReport.value,
    };
  }

  IssueReportModel copyWith({
    String? reportId,
    String? userId,
    String? category,
    String? description,
    String? attachmentUrl,
    IssueReportStatus? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IssueReportModel(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      description: description ?? this.description,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}