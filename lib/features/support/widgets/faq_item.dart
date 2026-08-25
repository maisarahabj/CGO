// TODO: Implement an expandable FAQ item.
import 'package:flutter/material.dart';

import '../models/faq_model.dart';

class FaqItem extends StatelessWidget {
  const FaqItem({required this.faq, super.key});

  final FaqModel faq;

  static const Color _blue = Color(0xFF176F9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB6D4E3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        iconColor: _blue,
        collapsedIconColor: _blue,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF303840),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            faq.category,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: _blue,
            ),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF5E6871),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
