class LegalDocumentModel {
  const LegalDocumentModel({
    required this.documentKey,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.updatedBy,
  });

  final String documentKey;
  final String title;
  final String content;
  final DateTime updatedAt;
  final String? updatedBy;

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    return LegalDocumentModel(
      documentKey: (json['document_key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedBy: json['updated_by']?.toString(),
    );
  }
}
