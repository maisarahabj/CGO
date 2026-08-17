// TODO: Manage admin FAQ editing state through FaqService.
import 'package:flutter/foundation.dart';

import '../models/faq_model.dart';
import '../services/faq_service.dart';

class AdminFaqController extends ChangeNotifier {
  AdminFaqController(this._service);

  final FaqService _service;

  List<FaqModel> _faqs = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<FaqModel> get faqs => List.unmodifiable(_faqs);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadFaqs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _faqs = await _service.getAllFaqs();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addFaq({
    required String category,
    required String question,
    required String answer,
    required String targetRole,
    required String displayOrderText,
    required bool isPublished,
  }) async {
    final validationError = _validate(
      category: category,
      question: question,
      answer: answer,
      targetRole: targetRole,
      displayOrderText: displayOrderText,
    );

    if (validationError != null) {
      return validationError;
    }

    final displayOrder = int.parse(displayOrderText.trim());

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addFaq(
        category: category,
        question: question,
        answer: answer,
        targetRole: targetRole,
        displayOrder: displayOrder,
        isPublished: isPublished,
      );

      await loadFaqs();
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

  Future<String?> updateFaq({
    required String faqId,
    required String category,
    required String question,
    required String answer,
    required String targetRole,
    required String displayOrderText,
    required bool isPublished,
  }) async {
    final validationError = _validate(
      category: category,
      question: question,
      answer: answer,
      targetRole: targetRole,
      displayOrderText: displayOrderText,
    );

    if (validationError != null) {
      return validationError;
    }

    final displayOrder = int.parse(displayOrderText.trim());

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateFaq(
        faqId: faqId,
        category: category,
        question: question,
        answer: answer,
        targetRole: targetRole,
        displayOrder: displayOrder,
        isPublished: isPublished,
      );

      await loadFaqs();
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

  Future<String?> togglePublished(FaqModel faq) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setPublished(
        faqId: faq.faqId,
        isPublished: !faq.isPublished,
      );

      await loadFaqs();
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

  Future<String?> deleteFaq(FaqModel faq) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteFaq(faq.faqId);

      await loadFaqs();
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

  String? _validate({
    required String category,
    required String question,
    required String answer,
    required String targetRole,
    required String displayOrderText,
  }) {
    if (question.trim().isEmpty) {
      return 'Question is required.';
    }

    if (answer.trim().isEmpty) {
      return 'Answer is required.';
    }

    if (category.trim().isEmpty) {
      return 'Category is required.';
    }

    if (targetRole != 'regular' && targetRole != 'admin') {
      return 'Please select a valid target role.';
    }

    final displayOrder = int.tryParse(displayOrderText.trim());

    if (displayOrder == null) {
      return 'Display order must be a whole number.';
    }

    if (displayOrder < 0) {
      return 'Display order cannot be negative.';
    }

    return null;
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('row-level security') ||
        text.contains('42501') ||
        text.contains('permission denied')) {
      return 'You do not have permission to manage FAQs.';
    }

    return text;
  }
}
