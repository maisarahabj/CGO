import 'package:flutter/material.dart';

import '../services/legal_document_service.dart';
import 'legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      documentKey: LegalDocumentService.privacyPolicyKey,
      subtitle: 'Privacy Policy',
    );
  }
}
