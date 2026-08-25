import 'package:flutter/material.dart';

import '../services/legal_document_service.dart';
import 'legal_document_screen.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      documentKey: LegalDocumentService.termsOfUseKey,
      subtitle: 'Terms of Use',
    );
  }
}
