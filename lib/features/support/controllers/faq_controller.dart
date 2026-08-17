// TODO: Manage FAQ loading, categories, filtering, data, and errors.
import 'package:flutter/foundation.dart';

import '../models/faq_model.dart';
import '../services/faq_service.dart';

class FaqController extends ChangeNotifier {
  FaqController({FaqService? service}) : _service = service ?? FaqService();

  final FaqService _service;

  List<FaqModel> _faqs = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final values = _faqs
        .map((faq) => faq.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['All', ...values];
  }

  List<FaqModel> get filteredFaqs {
    final query = _searchQuery.trim().toLowerCase();

    return _faqs.where((faq) {
      final categoryMatches =
          _selectedCategory == 'All' ||
          faq.category.toLowerCase() == _selectedCategory.toLowerCase();

      final searchMatches =
          query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.category.toLowerCase().contains(query);

      return categoryMatches && searchMatches;
    }).toList();
  }

  Future<void> loadFaqs() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _faqs = await _service.getPublishedRegularFaqs();

      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }
    } catch (error, stackTrace) {
      debugPrint('FAQ load error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _faqs = [];
      _errorMessage = 'Unable to load frequently asked questions.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) {
      return;
    }

    _searchQuery = value;

    notifyListeners();
  }

  void setCategory(String category) {
    if (!categories.contains(category)) {
      return;
    }

    if (_selectedCategory == category) {
      return;
    }

    _selectedCategory = category;

    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';

    notifyListeners();
  }
}
