// TODO: Map this model to the exact columns in public.faq.
class FaqModel {
  const FaqModel({
    required this.faqId,
    required this.category,
    required this.question,
    required this.answer,
    required this.targetRole,
    required this.displayOrder,
    required this.isPublished,
  });

  final String faqId;
  final String category;
  final String question;
  final String answer;
  final String targetRole;
  final int displayOrder;
  final bool isPublished;

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
    );
  }
}
