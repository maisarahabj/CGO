// TODO: Implement the admin screen for creating, editing, and deleting FAQs.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/admin_faq_controller.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';

class AdminManageFaqScreen extends StatelessWidget {
  const AdminManageFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminFaqController(FaqService())..loadFaqs(),
      child: const _AdminManageFaqBody(),
    );
  }
}

class _AdminManageFaqBody extends StatefulWidget {
  const _AdminManageFaqBody();

  @override
  State<_AdminManageFaqBody> createState() => _AdminManageFaqBodyState();
}

class _AdminManageFaqBodyState extends State<_AdminManageFaqBody> {
  String _searchQuery = '';
  String _roleFilter = 'all';

  List<FaqModel> _filteredFaqs(List<FaqModel> faqs) {
    final query = _searchQuery.trim().toLowerCase();

    return faqs.where((faq) {
      final matchesRole = _roleFilter == 'all' || faq.targetRole == _roleFilter;

      final matchesSearch =
          query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.category.toLowerCase().contains(query);

      return matchesRole && matchesSearch;
    }).toList();
  }

  Future<void> _showFaqDialog({FaqModel? faq}) async {
    final adminController = context.read<AdminFaqController>();
    final isEditing = faq != null;

    final questionController = TextEditingController(text: faq?.question ?? '');
    final answerController = TextEditingController(text: faq?.answer ?? '');
    final categoryController = TextEditingController(text: faq?.category ?? '');
    final displayOrderController = TextEditingController(
      text: (faq?.displayOrder ?? 1).toString(),
    );

    String targetRole = faq?.targetRole ?? 'regular';
    bool isPublished = faq?.isPublished ?? true;
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> saveFaq() async {
                if (isSaving) {
                  return;
                }

                setDialogState(() {
                  isSaving = true;
                });

                String? error;

                if (isEditing) {
                  error = await adminController.updateFaq(
                    faqId: faq.faqId,
                    category: categoryController.text,
                    question: questionController.text,
                    answer: answerController.text,
                    targetRole: targetRole,
                    displayOrderText: displayOrderController.text,
                    isPublished: isPublished,
                  );
                } else {
                  error = await adminController.addFaq(
                    category: categoryController.text,
                    question: questionController.text,
                    answer: answerController.text,
                    targetRole: targetRole,
                    displayOrderText: displayOrderController.text,
                    isPublished: isPublished,
                  );
                }

                if (!dialogContext.mounted) {
                  return;
                }

                if (error != null) {
                  setDialogState(() {
                    isSaving = false;
                  });

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text(error)));

                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'FAQ updated successfully.'
                          : 'FAQ added successfully.',
                    ),
                  ),
                );
              }

              return AlertDialog(
                title: Text(isEditing ? 'Edit FAQ' : 'Add FAQ'),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: questionController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Question *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: answerController,
                          enabled: !isSaving,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Answer *',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: categoryController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: targetRole,
                          decoration: const InputDecoration(
                            labelText: 'Target Role *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'regular',
                              child: Text('Regular User'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    targetRole = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: displayOrderController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Display Order *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Published'),
                          subtitle: Text(
                            isPublished
                                ? 'Visible to the selected audience.'
                                : 'Hidden from users.',
                          ),
                          value: isPublished,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isPublished = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving ? null : saveFaq,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Add FAQ'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      questionController.dispose();
      answerController.dispose();
      categoryController.dispose();
      displayOrderController.dispose();
    }
  }

  Future<void> _togglePublished(FaqModel faq) async {
    final controller = context.read<AdminFaqController>();

    final error = await controller.togglePublished(faq);

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          faq.isPublished
              ? 'FAQ unpublished successfully.'
              : 'FAQ published successfully.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FaqModel faq) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete FAQ?'),
          content: Text(
            'Are you sure you want to permanently delete:\n\n'
            '"${faq.question}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final controller = context.read<AdminFaqController>();
    final error = await controller.deleteFaq(faq);

    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('FAQ deleted successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFaqDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add FAQ'),
      ),
      body: Consumer<AdminFaqController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.faqs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.faqs.isEmpty) {
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
                      onPressed: controller.loadFaqs,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final filteredFaqs = _filteredFaqs(controller.faqs);

          return RefreshIndicator(
            onRefresh: controller.loadFaqs,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _roleFilter == 'all',
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Regular'),
                        selected: _roleFilter == 'regular',
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'regular';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Admin'),
                        selected: _roleFilter == 'admin',
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = 'admin';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredFaqs.length} FAQ'
                  '${filteredFaqs.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (filteredFaqs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.help_outline, size: 48),
                          SizedBox(height: 12),
                          Text('No FAQs found.'),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredFaqs.map(
                    (faq) => _FaqAdminCard(
                      faq: faq,
                      isBusy: controller.isSubmitting,
                      onEdit: () => _showFaqDialog(faq: faq),
                      onTogglePublished: () => _togglePublished(faq),
                      onDelete: () => _confirmDelete(faq),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqAdminCard extends StatelessWidget {
  const _FaqAdminCard({
    required this.faq,
    required this.isBusy,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final FaqModel faq;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: faq.isPublished
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    faq.isPublished ? 'Published' : 'Unpublished',
                    style: TextStyle(
                      color: faq.isPublished
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(faq.answer),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(faq.category)),
                Chip(
                  label: Text(faq.targetRole == 'admin' ? 'Admin' : 'Regular'),
                ),
                Chip(label: Text('Order ${faq.displayOrder}')),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onTogglePublished,
                  icon: Icon(
                    faq.isPublished
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(faq.isPublished ? 'Unpublish' : 'Publish'),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
