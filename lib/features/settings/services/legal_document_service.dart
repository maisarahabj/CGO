import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/legal_document_model.dart';

class LegalDocumentService {
  LegalDocumentService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'legal_documents';

  static const String privacyPolicyKey = 'privacy_policy';
  static const String termsOfUseKey = 'terms_of_use';

  Future<LegalDocumentModel> getDocument(String documentKey) async {
    final data = await _client
        .from(_table)
        .select('document_key, title, content, updated_at, updated_by')
        .eq('document_key', documentKey)
        .single();

    return LegalDocumentModel.fromJson(data);
  }

  Future<void> updateDocument({
    required String documentKey,
    required String content,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to edit legal documents.');
    }

    await _client
        .from(_table)
        .update({
          'content': content.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'updated_by': user.id,
        })
        .eq('document_key', documentKey);
  }
}
