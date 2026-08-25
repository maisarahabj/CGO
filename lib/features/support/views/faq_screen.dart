import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
 
import '../../../core/constants/app_assets.dart';
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
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: 'Frequently Asked Questions',
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2A77B4),
                      ),
                    );
                  }
 
                  if (_controller.errorMessage != null) {
                    return _errorState();
                  }
 
                  return RefreshIndicator(
                    onRefresh: _controller.loadFaqs,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
                      children: [
                        const Text(
                          'How can we help?',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF115388),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Browse common questions or search for the help you need.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF68727D),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          onChanged: _controller.setSearchQuery,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF424242),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search frequently asked questions',
                            hintStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              color: Color(0xFF919191),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF2A77B4),
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _controller.setSearchQuery('');
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF777777),
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A77B4),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: const BorderSide(
                                color: Color(0xFF9DC7DD),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: const BorderSide(
                                color: Color(0xFF2A77B4),
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FaqCategoryFilter(
                          categories: _controller.categories,
                          selectedCategory: _controller.selectedCategory,
                          onSelected: _controller.setCategory,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'FAQs',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38358E),
                                ),
                              ),
                            ),
                            Text(
                              '${_controller.filteredFaqs.length} found',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11.5,
                                color: Color(0xFF7A8289),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_controller.filteredFaqs.isEmpty)
                          _emptyState()
                        else
                          ..._controller.filteredFaqs.map(
                            (faq) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FaqItem(
                                key: ValueKey(faq.faqId),
                                faq: faq,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDDE5E9),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 38,
            color: Color(0xFF9299A0),
          ),
          SizedBox(height: 10),
          Text(
            'No FAQs match your search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13.5,
              height: 1.4,
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
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage ?? 'Unable to load FAQs.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _controller.loadFaqs,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38358E),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _CampusSubpageHeader extends StatelessWidget {
  const _CampusSubpageHeader({
    required this.subtitle,
    required this.onBack,
    required this.onClose,
  });
 
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onClose;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  splashRadius: 22,
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 23,
                    color: Color(0xFF2A77B4),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Campus',
                              style: TextStyle(color: Color(0xFF38358E)),
                            ),
                            TextSpan(
                              text: 'GO',
                              style: TextStyle(color: Color(0xFFFF0000)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  splashRadius: 22,
                  onPressed: onClose,
                  icon: SvgPicture.asset(
                    AppAssets.closeButton,
                    width: 23,
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF115388),
            ),
          ),
        ],
      ),
    );
  }
}
