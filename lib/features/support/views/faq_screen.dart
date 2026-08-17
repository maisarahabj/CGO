// TODO: Implement the searchable FAQ screen.
import 'package:flutter/material.dart';

import '../controllers/faq_controller.dart';
import '../widgets/faq_category_filter.dart';
import '../widgets/faq_item.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late final FaqController _controller;

  final TextEditingController _searchController = TextEditingController();

  static const Color _blue = Color(0xFF176F9E);
  static const Color _darkBlue = Color(0xFF342C86);

  @override
  void initState() {
    super.initState();

    _controller = FaqController();
    _controller.loadFaqs();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: _blue),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: 'Campus',
                    style: TextStyle(color: _darkBlue),
                  ),
                  TextSpan(
                    text: 'GO',
                    style: TextStyle(color: Color(0xFFE31919)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _blue,
              ),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return _errorState();
          }

          return RefreshIndicator(
            onRefresh: _controller.loadFaqs,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SizedBox(height: 10),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'How can we help?',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Browse common questions or search '
                    'for the help you need.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: Color(0xFF68727D),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _controller.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search frequently asked questions',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _controller.setSearchQuery('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFF9DC4DA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: _blue, width: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                FaqCategoryFilter(
                  categories: _controller.categories,
                  selectedCategory: _controller.selectedCategory,
                  onSelected: _controller.setCategory,
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'FAQs',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                      ),
                      Text(
                        '${_controller.filteredFaqs.length} found',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: Color(0xFF7A8289),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (_controller.filteredFaqs.isEmpty)
                  _emptyState()
                else
                  ..._controller.filteredFaqs.map(
                    (faq) => FaqItem(key: ValueKey(faq.faqId), faq: faq),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_outlined, size: 36, color: Color(0xFF9299A0)),
          SizedBox(height: 9),
          Text(
            'No FAQs match your search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: Color(0xFF68727D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage ?? 'Unable to load FAQs.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _controller.loadFaqs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
