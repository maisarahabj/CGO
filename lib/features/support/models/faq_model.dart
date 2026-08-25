class FaqModel {
  const FaqModel({
    required this.faqId,
    required this.category,
    required this.question,
    required this.answer,
    required this.targetRole,
    required this.displayOrder,
    required this.isPublished,
    this.createdBy,
  });

  final String faqId;
  final String category;
  final String question;
  final String answer;
  final String targetRole;
  final int displayOrder;
  final bool isPublished;
  final String? createdBy;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      faqId: (json['faq_id'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      targetRole: (json['target_role'] ?? 'regular').toString(),
      displayOrder: json['display_order'] is num
          ? (json['display_order'] as num).toInt()
          : 0,
      isPublished: json['is_published'] as bool? ?? false,
      createdBy: json['created_by']?.toString(),
    );
  }

  FaqModel copyWith({
    String? faqId,
    String? category,
    String? question,
    String? answer,
    String? targetRole,
    int? displayOrder,
    bool? isPublished,
    String? createdBy,
  }) {
    return FaqModel(
      faqId: faqId ?? this.faqId,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      targetRole: targetRole ?? this.targetRole,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
