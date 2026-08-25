import 'dart:typed_data';
 
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 
import '../../../core/constants/app_assets.dart';
import '../controllers/issue_report_controller.dart';
import '../services/issue_report_service.dart';
import '../widgets/issue_report_form.dart';
import 'issue_report_history_screen.dart';
 
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
 
    if (picked == null) {
      return null;
    }
 
    final bytes = await picked.readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
 
    return (
      bytes: bytes,
      extension: extension,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: 'Report an Issue',
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: Consumer<IssueReportController>(
                builder: (context, controller, _) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Text(
                                'Tell us what happened',
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF115388),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                final currentController =
                                    context.read<IssueReportController>();
 
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChangeNotifierProvider<
                                        IssueReportController>.value(
                                      value: currentController,
                                      child:
                                          const IssueReportHistoryScreen(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.history_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'History',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Provide the details below so the CampusGO team can review the issue.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13.5,
                            height: 1.4,
                            color: Color(0xFF68727D),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF9DC7DD),
                              width: 1,
                            ),
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
                                  final success =
                                      await controller.submitReport(
                                    category: category,
                                    description: description,
                                    attachmentBytes: attachmentBytes,
                                    attachmentExtension:
                                        attachmentExtension,
                                  );
 
                                  if (!context.mounted) {
                                    return;
                                  }
 
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Report submitted!'
                                              : (controller.error ??
                                                  'Something went wrong.'),
                                        ),
                                        backgroundColor: success
                                            ? const Color(0xFF276749)
                                            : const Color(0xFFB3261E),
                                      ),
                                    );
 
                                  if (success) {
                                    Navigator.of(context).pop();
                                  }
                                },
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
