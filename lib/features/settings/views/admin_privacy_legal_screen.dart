import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/admin_legal_document_controller.dart';
import '../models/legal_document_model.dart';
import '../services/legal_document_service.dart';

class AdminPrivacyLegalScreen extends StatelessWidget {
  const AdminPrivacyLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AdminLegalDocumentController(LegalDocumentService())..loadDocuments(),
      child: const _AdminPrivacyLegalBody(),
    );
  }
}

class _AdminPrivacyLegalBody extends StatefulWidget {
  const _AdminPrivacyLegalBody();

  @override
  State<_AdminPrivacyLegalBody> createState() => _AdminPrivacyLegalBodyState();
}

class _AdminPrivacyLegalBodyState extends State<_AdminPrivacyLegalBody> {
  Future<void> _editDocument(LegalDocumentModel document) async {
    final controller = context.read<AdminLegalDocumentController>();

    final textController = TextEditingController(text: document.content);

    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> save() async {
                if (isSaving) {
                  return;
                }

                setDialogState(() {
                  isSaving = true;
                });

                final error = await controller.updateDocument(
                  documentKey: document.documentKey,
                  content: textController.text,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                if (error != null) {
                  setDialogState(() {
                    isSaving = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(
                      this.context,
                    ).showSnackBar(SnackBar(content: Text(error)));
                  }

                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('${document.title} updated successfully.'),
                  ),
                );
              }

              return AlertDialog(
                title: Text('Edit ${document.title}'),
                content: SizedBox(
                  width: 600,
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: textController,
                      enabled: !isSaving,
                      minLines: 15,
                      maxLines: 24,
                      decoration: const InputDecoration(
                        labelText: 'Document content',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      textController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(title: const Text('Privacy & Legal')),
      body: Consumer<AdminLegalDocumentController>(
        builder: (context, controller, _) {
          if (controller.isLoading &&
              controller.privacyPolicy == null &&
              controller.termsOfUse == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null &&
              controller.privacyPolicy == null &&
              controller.termsOfUse == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.loadDocuments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadDocuments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                const Text(
                  'Privacy & Legal',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF115388),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage the legal information displayed to CampusGO users.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF68727D),
                  ),
                ),
                const SizedBox(height: 22),

                if (controller.privacyPolicy != null)
                  _LegalAdminCard(
                    document: controller.privacyPolicy!,
                    icon: Icons.shield_outlined,
                    isBusy: controller.isSubmitting,
                    onEdit: () => _editDocument(controller.privacyPolicy!),
                  ),

                const SizedBox(height: 14),

                if (controller.termsOfUse != null)
                  _LegalAdminCard(
                    document: controller.termsOfUse!,
                    icon: Icons.description_outlined,
                    isBusy: controller.isSubmitting,
                    onEdit: () => _editDocument(controller.termsOfUse!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalAdminCard extends StatelessWidget {
  const _LegalAdminCard({
    required this.document,
    required this.icon,
    required this.isBusy,
    required this.onEdit,
  });

  final LegalDocumentModel document;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final date = document.updatedAt.toLocal();

    final updatedText =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF2A77B4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    document.title,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38358E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              document.content,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Last updated: $updatedText',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Color(0xFF858585),
              ),
            ),
            const Divider(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
