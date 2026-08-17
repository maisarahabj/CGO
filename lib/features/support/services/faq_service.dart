// TODO: Implement published FAQ queries.
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
          'target_role, display_order, is_published',
        )
        .eq('target_role', 'regular')
        .eq('is_published', true)
        .order('category')
        .order('display_order')
        .order('faq_id');

    return data.map(FaqModel.fromJson).toList();
  }
}
