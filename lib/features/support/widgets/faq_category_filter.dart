// TODO: Implement the FAQ category filter.
import 'package:flutter/material.dart';

class FaqCategoryFilter extends StatelessWidget {
  const FaqCategoryFilter({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  static const Color _blue = Color(0xFF176F9E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];

          final selected = category == selectedCategory;

          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _blue,
              ),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: _blue,
            backgroundColor: Colors.white,
            side: const BorderSide(color: _blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (_) {
              onSelected(category);
            },
          );
        },
      ),
    );
  }
}
