import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/issue_report_controller.dart';
import '../models/issue_report_model.dart';
import '../widgets/issue_status_badge.dart';

class IssueReportHistoryScreen extends StatefulWidget {
  const IssueReportHistoryScreen({super.key});

  @override
  State<IssueReportHistoryScreen> createState() => _IssueReportHistoryScreenState();
}

class _IssueReportHistoryScreenState extends State<IssueReportHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssueReportController>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your Reports'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF115388),
        elevation: 0,
      ),
      body: Consumer<IssueReportController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null) {
            return Center(child: Text(controller.error!));
          }
          if (controller.reports.isEmpty) {
            return const Center(child: Text('No reports yet.', style: TextStyle(color: Colors.grey)));
          }

          return RefreshIndicator(
            onRefresh: controller.loadReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.reports.length,
              itemBuilder: (context, index) => _ReportCard(report: controller.reports[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IssueReportModel report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(report.createdAt);

    return Container(
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
              IssueStatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(report.description, style: const TextStyle(color: Color(0xFF424242))),
          const SizedBox(height: 6),
          Text(dateStr, style: const TextStyle(color: Color(0xFF959BB1), fontSize: 12)),
          if (report.attachmentUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(report.attachmentUrl!, height: 120, fit: BoxFit.cover),
            ),
          ],
          if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Admin note: ${report.adminNotes}', style: const TextStyle(color: Color(0xFF61727D), fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}