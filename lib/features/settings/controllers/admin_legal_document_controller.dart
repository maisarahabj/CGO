import 'package:flutter/foundation.dart';

import '../models/legal_document_model.dart';
import '../services/legal_document_service.dart';

class AdminLegalDocumentController extends ChangeNotifier {
  AdminLegalDocumentController(this._service);

  final LegalDocumentService _service;

  LegalDocumentModel? _privacyPolicy;
  LegalDocumentModel? _termsOfUse;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  LegalDocumentModel? get privacyPolicy => _privacyPolicy;
  LegalDocumentModel? get termsOfUse => _termsOfUse;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final documents = await Future.wait([
        _service.getDocument(LegalDocumentService.privacyPolicyKey),
        _service.getDocument(LegalDocumentService.termsOfUseKey),
      ]);

      _privacyPolicy = documents[0];
      _termsOfUse = documents[1];
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateDocument({
    required String documentKey,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      return 'Document content cannot be empty.';
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateDocument(documentKey: documentKey, content: content);

      await loadDocuments();

      return null;
    } catch (error) {
      final message = _friendlyError(error);
      _errorMessage = message;
      return message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('row-level security') ||
        text.contains('42501') ||
        text.contains('permission denied')) {
      return 'You do not have permission to edit legal documents.';
    }

    return text;
  }
}
