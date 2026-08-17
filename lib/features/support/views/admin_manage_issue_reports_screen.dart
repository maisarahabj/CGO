import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/admin_issue_report_controller.dart';
import '../models/issue_report_model.dart';
import '../models/issue_report_status.dart';
import '../services/issue_report_service.dart';

/// Admin-only screen: review issue reports, update status, and leave notes.
/// Reachable only for role == UserRole.admin (guarded at the router, same
/// as AdminManageBookingsScreen — no auth params needed here).
///
/// Self-contained: builds its own locally-scoped
/// AdminIssueReportController, matching AdminManageBookingsScreen's pattern.
class AdminManageIssueReportsScreen extends StatelessWidget {
  const AdminManageIssueReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminIssueReportController(IssueReportService(Supabase.instance.client)),
      child: const _AdminManageIssueReportsBody(),
    );
  }
}

class _AdminManageIssueReportsBody extends StatefulWidget {
  const _AdminManageIssueReportsBody();

  @override
  State<_AdminManageIssueReportsBody> createState() => _AdminManageIssueReportsScreenState();
}

class _AdminManageIssueReportsScreenState extends State<_AdminManageIssueReportsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminIssueReportController>().loadReports();
    });
  }

  Future<void> _reviewReport(BuildContext context, IssueReportModel report) async {
    final notesController = TextEditingController(text: report.adminNotes ?? '');
    IssueReportStatus selectedStatus = report.status;

    final result = await showDialog<IssueReportStatus>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Review Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.description, style: const TextStyle(color: Color(0xFF424242))),
              const SizedBox(height: 16),
              DropdownButton<IssueReportStatus>(
                value: selectedStatus,
                isExpanded: true,
                items: IssueReportStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => selectedStatus = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Admin notes', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedStatus),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final controller = context.read<AdminIssueReportController>();
      final success = await controller.updateStatus(
        report.reportId,
        status: result,
        adminNotes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Report updated.' : (controller.error ?? 'Failed.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Issue Reports'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF115388),
        elevation: 0,
      ),
      body: Consumer<AdminIssueReportController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              _buildFilterChips(controller),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                        ? Center(child: Text(controller.error!))
                        : controller.reports.isEmpty
                            ? const Center(child: Text('No reports found.', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: controller.reports.length,
                                itemBuilder: (context, index) {
                                  final report = controller.reports[index];
                                  return _AdminReportCard(
                                    report: report,
                                    onTap: () => _reviewReport(context, report),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(AdminIssueReportController controller) {
    final options = <String, IssueReportStatus?>{
      'New': IssueReportStatus.newReport,
      'In Review': IssueReportStatus.inReview,
      'Resolved': IssueReportStatus.resolved,
      'Rejected': IssueReportStatus.rejected,
      'All': null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.entries.map((entry) {
            final selected = controller.filter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: selected,
                selectedColor: const Color(0xFF2A77B4),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                onSelected: (_) => controller.setFilter(entry.value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final IssueReportModel report;
  final VoidCallback onTap;

  const _AdminReportCard({required this.report, required this.onTap});

  Color get _statusColor {
    switch (report.status) {
      case IssueReportStatus.newReport:
        return const Color(0xFF2A77B4);
      case IssueReportStatus.inReview:
        return const Color(0xFF767676);
      case IssueReportStatus.resolved:
        return const Color(0xFF2E9E4F);
      case IssueReportStatus.rejected:
        return const Color(0xFFE51717);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(report.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(color: const Color(0xFF2A77B4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(report.category, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2A77B4))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(52)),
                  child: Text(report.status.value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF424242))),
            const SizedBox(height: 6),
            Text(dateStr, style: const TextStyle(color: Color(0xFF959BB1), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}