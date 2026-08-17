import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/issue_report_status.dart';

/// Reusable issue-report submission form. Styled consistently with the
/// bookings feature's pill inputs (#2A77B4 borders) since no Figma exists
/// for this screen yet.
///
/// The attachment picker is intentionally simple: caller supplies
/// onPickImage (wire to image_picker or file_picker in the screen) and
/// this widget just displays the picked bytes/filename and lets the user
/// clear it. This widget never touches Supabase directly — only the
/// screen/controller does.
class IssueReportForm extends StatefulWidget {
  final void Function({
    required String category,
    required String description,
    Uint8List? attachmentBytes,
    String? attachmentExtension,
  }) onSubmit;
  final Future<({Uint8List bytes, String extension})?> Function() onPickImage;
  final bool isSubmitting;

  const IssueReportForm({
    super.key,
    required this.onSubmit,
    required this.onPickImage,
    this.isSubmitting = false,
  });

  @override
  State<IssueReportForm> createState() => _IssueReportFormState();
}

class _IssueReportFormState extends State<IssueReportForm> {
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  Uint8List? _attachmentBytes;
  String? _attachmentExtension;

  static const _borderBlue = Color(0xFF2A77B4);

  Future<void> _pickImage() async {
    final result = await widget.onPickImage();
    if (result != null) {
      setState(() {
        _attachmentBytes = result.bytes;
        _attachmentExtension = result.extension;
      });
    }
  }

  void _submit() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a category.')));
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please describe the issue.')));
      return;
    }

    widget.onSubmit(
      category: _selectedCategory!,
      description: _descriptionController.text.trim(),
      attachmentBytes: _attachmentBytes,
      attachmentExtension: _attachmentExtension,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF919191))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderBlue),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('Select a category'),
              items: IssueReportCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF919191))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FF),
            border: Border.all(color: _borderBlue),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Describe what happened, and where.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Attach a screenshot (optional)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF919191))),
        const SizedBox(height: 6),
        if (_attachmentBytes != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_attachmentBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => setState(() {
                    _attachmentBytes = null;
                    _attachmentExtension = null;
                  }),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Add screenshot'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        const SizedBox(height: 24),
        InkWell(
          onTap: widget.isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(52),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B38A7), Color(0xFFFF2B00)],
              ),
              borderRadius: BorderRadius.circular(52),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.48), blurRadius: 7.1, offset: const Offset(0, 4))],
            ),
            child: widget.isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Report', style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}