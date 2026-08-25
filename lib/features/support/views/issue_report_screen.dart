import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/issue_report_controller.dart';
import '../widgets/issue_report_form.dart';
import 'issue_report_history_screen.dart';
import '../services/issue_report_service.dart';

/// Issue report submission screen. Reachable only for role == UserRole.user
/// (add the route in app_router.dart the same way bookings was wired in —
/// see AppRoutes.bookings for the pattern to copy).
///
/// Self-contained: builds its own locally-scoped IssueReportController
/// using the real Supabase auth user id, matching BookingsScreen's pattern
/// (no global Provider tree in this app).
///
/// NOTE: requires the `image_picker` package — run
/// `flutter pub add image_picker` before using this screen.
class IssueReportScreen extends StatelessWidget {
  const IssueReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return ChangeNotifierProvider(
      create: (_) => IssueReportController(
        IssueReportService(Supabase.instance.client),
        userId,
      ),
      child: const _IssueReportScreenBody(),
    );
  }
}

class _IssueReportScreenBody extends StatelessWidget {
  const _IssueReportScreenBody();

  Future<({Uint8List bytes, String extension})?> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
    return (bytes: bytes, extension: extension);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF115388),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              final controller = context.read<IssueReportController>();

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ChangeNotifierProvider<IssueReportController>.value(
                        value: controller,
                        child: const IssueReportHistoryScreen(),
                      ),
                ),
              );
            },
            child: const Text('History'),
          ),
        ],
      ),
      body: Consumer<IssueReportController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                border: Border.all(color: const Color(0xFF2A77B4)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IssueReportForm(
                isSubmitting: controller.isSubmitting,
                onPickImage: _pickImage,
                onSubmit:
                    ({
                      required category,
                      required description,
                      attachmentBytes,
                      attachmentExtension,
                    }) async {
                      final success = await controller.submitReport(
                        category: category,
                        description: description,
                        attachmentBytes: attachmentBytes,
                        attachmentExtension: attachmentExtension,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Report submitted!'
                                  : (controller.error ??
                                        'Something went wrong.'),
                            ),
                          ),
                        );
                        if (success) Navigator.pop(context);
                      }
                    },
              ),
            ),
          );
        },
      ),
    );
  }
}
