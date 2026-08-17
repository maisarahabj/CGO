import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/faq_model.dart';

class FaqService {
  FaqService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'faq';

  /// User-facing FAQ list.
  ///
  /// Only published FAQs intended for regular users are returned.
  Future<List<FaqModel>> getPublishedRegularFaqs() async {
    final List<Map<String, dynamic>> data = await _client
        .from(_table)
        .select(
          'faq_id, category, question, answer, '
          'target_role, display_order, is_published, created_by',
        )
        .eq('target_role', 'regular')
        .eq('is_published', true)
        .order('category')
        .order('display_order')
        .order('faq_id');

    return data.map(FaqModel.fromJson).toList();
  }

  /// Admin-facing FAQ list.
  ///
  /// Supabase RLS ensures only administrators can read unpublished
  /// and admin-targeted FAQ records.
  Future<List<FaqModel>> getAllFaqs() async {
    final List<Map<String, dynamic>> data = await _client
        .from(_table)
        .select(
          'faq_id, category, question, answer, '
          'target_role, display_order, is_published, created_by',
        )
        .order('category')
        .order('display_order')
        .order('faq_id');

    return data.map(FaqModel.fromJson).toList();
  }

  Future<void> addFaq({
    required String category,
    required String question,
    required String answer,
    required String targetRole,
    required int displayOrder,
    required bool isPublished,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to create an FAQ.');
    }

    final faqId = 'faq_${DateTime.now().microsecondsSinceEpoch}';

    await _client.from(_table).insert({
      'faq_id': faqId,
      'category': category.trim(),
      'question': question.trim(),
      'answer': answer.trim(),
      'target_role': targetRole,
      'display_order': displayOrder,
      'is_published': isPublished,
      'created_by': user.id,
    });
  }

  Future<void> updateFaq({
    required String faqId,
    required String category,
    required String question,
    required String answer,
    required String targetRole,
    required int displayOrder,
    required bool isPublished,
  }) async {
    await _client
        .from(_table)
        .update({
          'category': category.trim(),
          'question': question.trim(),
          'answer': answer.trim(),
          'target_role': targetRole,
          'display_order': displayOrder,
          'is_published': isPublished,
        })
        .eq('faq_id', faqId);
  }

  Future<void> setPublished({
    required String faqId,
    required bool isPublished,
  }) async {
    await _client
        .from(_table)
        .update({'is_published': isPublished})
        .eq('faq_id', faqId);
  }

  Future<void> deleteFaq(String faqId) async {
    await _client.from(_table).delete().eq('faq_id', faqId);
  }
}
