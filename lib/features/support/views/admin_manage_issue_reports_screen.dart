import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/admin_issue_report_controller.dart';
import '../models/issue_report_model.dart';
import '../models/issue_report_status.dart';
import '../services/issue_report_service.dart';

class AdminManageIssueReportsScreen extends StatelessWidget {
  const AdminManageIssueReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminIssueReportController(
        IssueReportService(Supabase.instance.client),
      ),
      child: const _AdminManageIssueReportsBody(),
    );
  }
}

class _AdminManageIssueReportsBody extends StatefulWidget {
  const _AdminManageIssueReportsBody();

  @override
  State<_AdminManageIssueReportsBody> createState() =>
      _AdminManageIssueReportsScreenState();
}

class _AdminManageIssueReportsScreenState
    extends State<_AdminManageIssueReportsBody> {
  static const _borderBlue = Color(0xFF2A77B4);
  static const _darkBlue = Color(0xFF115388);
  static const _textGrey = Color(0xFF424242);
  static const _lightBackground = Color(0xFFF9F9F9);

  // Status colours
  static const _newBlue = Color(0xFF2A77B4);
  static const _reviewAmber = Color(0xFFE6A817);
  static const _resolvedGreen = Color(0xFF2E9E4F);
  static const _rejectedRed = Color(0xFFE51717);

  static const _minNotesLength = 15;

  static const _lowEffortNotes = {
    'no',
    'no.',
    'cannot',
    'can\'t',
    'nope',
    'na',
    'n/a',
    'not possible',
    'rejected',
    'denied',
    'ok',
    'okay',
    'done',
  };

  static const _adminNoteOptions = [
    'Issue confirmed and fixed',
    'Issue confirmed, scheduled for repair',
    'Duplicate of an existing report',
    'Unable to reproduce the issue',
    'Insufficient information to investigate',
    'Not an actual issue — working as intended',
    'Escalated to facilities/maintenance team',
    'Escalated to IT/technical team',
    'Outside the scope of this report type',
    'Resolved — no further action needed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminIssueReportController>().loadReports();
    });
  }

  String? _validateAdminNotes(String notes) {
    final trimmed = notes.trim();

    if (trimmed.isEmpty) {
      return 'Please explain your decision so the reporter understands.';
    }

    if (trimmed.length < _minNotesLength) {
      return 'Please provide a more detailed explanation '
          '(at least $_minNotesLength characters).';
    }

    if (_lowEffortNotes.contains(trimmed.toLowerCase())) {
      return 'Please give a real explanation, not just a one-word answer.';
    }

    return null;
  }

  Color _statusColor(IssueReportStatus status) {
    switch (status) {
      case IssueReportStatus.newReport:
        return _newBlue;
      case IssueReportStatus.inReview:
        return _reviewAmber;
      case IssueReportStatus.resolved:
        return _resolvedGreen;
      case IssueReportStatus.rejected:
        return _rejectedRed;
    }
  }

  Future<void> _reviewReport(
    BuildContext context,
    IssueReportModel report,
  ) async {
    final notesController =
        TextEditingController(text: report.adminNotes ?? '');

    IssueReportStatus selectedStatus = report.status;
    String? notesError;
    String? selectedNoteOption;

    final result = await showModalBottomSheet<IssueReportStatus>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 4,
                  bottom:
                      MediaQuery.of(sheetContext).viewInsets.bottom + 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHeader(),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightBackground,
                        border: Border.all(color: _borderBlue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  report.category,
                                  style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _darkBlue,
                                  ),
                                ),
                              ),
                              _StatusBadge(
                                status: report.status,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: _borderBlue.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            report.description,
                            style: const TextStyle(
                              fontFamily: 'Roboto Condensed',
                              fontSize: 15,
                              height: 1.35,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const _FieldLabel(label: 'Status'),

                    const SizedBox(height: 7),

                    _StyledDropdown<IssueReportStatus>(
                      value: selectedStatus,
                      items: IssueReportStatus.values,
                      itemLabel: (status) => status.value,
                      itemColor: (status) => _statusColor(status),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 22),

                    const _FieldLabel(label: 'Admin notes'),

                    const SizedBox(height: 4),

                    const Text(
                      'Explain your decision clearly — the reporter will see this.',
                      style: TextStyle(
                        fontFamily: 'Roboto Condensed',
                        fontSize: 12,
                        color: Color(0xFF747474),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _borderBlue),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 2,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedNoteOption,
                          hint: const Text(
                            'Select a reason (Compulsory)',
                            style: TextStyle(
                              fontFamily: 'Roboto Flex',
                              color: Color(0xFF9A9A9A),
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF868DA6),
                          ),
                          items: _adminNoteOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto Flex',
                                      fontSize: 14,
                                      color: _textGrey,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              selectedNoteOption = value;
                              if (value != null &&
                                  value != 'Other' &&
                                  notesController.text.trim().isEmpty) {
                                notesController.text = '$value. ';
                                notesController.selection =
                                    TextSelection.collapsed(
                                  offset: notesController.text.length,
                                );
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FF),
                        border: Border.all(
                          color:
                              notesError != null ? Colors.red : _borderBlue,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TextField(
                        controller: notesController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontFamily: 'Roboto Condensed',
                          fontSize: 15,
                          color: _textGrey,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your explanation...',
                          hintStyle: TextStyle(
                            color: Color(0xFF9A9A9A),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) {
                          if (notesError != null) {
                            setSheetState(() {
                              notesError = null;
                            });
                          }
                        },
                      ),
                    ),

                    if (notesError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        notesError!,
                        style: const TextStyle(
                          fontFamily: 'Roboto Condensed',
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              side: const BorderSide(
                                color: _borderBlue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                                color: _borderBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GradientButton(
                            label: 'Save',
                            onTap: () {
                              final error =
                                  _validateAdminNotes(notesController.text);

                              if (error != null) {
                                setSheetState(() {
                                  notesError = error;
                                });
                                return;
                              }

                              Navigator.pop(
                                sheetContext,
                                selectedStatus,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      final controller =
          context.read<AdminIssueReportController>();

      final success = await controller.updateStatus(
        report.reportId,
        status: result,
        adminNotes: notesController.text.trim(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Report updated.'
                  : (controller.error ?? 'Failed.'),
            ),
          ),
        );
      }
    }

    notesController.dispose();
  }

  Widget _buildSheetHeader() {
    return Column(
      children: [
        Center(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
              children: [
                TextSpan(
                  text: 'Campus',
                  style: TextStyle(color: Color(0xFF38358E)),
                ),
                TextSpan(
                  text: 'GO',
                  style: TextStyle(color: Color(0xFFE51717)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review Report',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _darkBlue,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 1.2,
          color: _borderBlue,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AdminIssueReportController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : controller.error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  controller.error!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                32,
                              ),
                              children: [
                                _buildFilterChips(controller),

                                const SizedBox(height: 18),

                                if (controller.reports.isEmpty)
                                  _buildEmptyState()
                                else
                                  ...controller.reports.map(
                                    (report) => _AdminReportCard(
                                      report: report,
                                      onTap: () =>
                                          _reviewReport(context, report),
                                    ),
                                  ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF185C92),
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                  children: [
                    TextSpan(
                      text: 'Campus',
                      style: TextStyle(
                        color: Color(0xFF38358E),
                      ),
                    ),
                    TextSpan(
                      text: 'GO',
                      style: TextStyle(
                        color: Color(0xFFE51717),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage Issue Reports',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1.2,
            color: _borderBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    AdminIssueReportController controller,
  ) {
    final options = <String, IssueReportStatus?>{
      'New': IssueReportStatus.newReport,
      'In Review': IssueReportStatus.inReview,
      'Resolved': IssueReportStatus.resolved,
      'Rejected': IssueReportStatus.rejected,
      'All': null,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final selected =
              controller.filter == entry.value;

          final color = entry.value == null
              ? _borderBlue
              : _statusColor(entry.value!);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () =>
                  controller.setFilter(entry.value),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  border: Border.all(
                    color: color,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: selected ? 0.10 : 0.06,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontFamily: 'Roboto Flex',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected
                        ? Colors.white
                        : color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: _lightBackground,
        border: Border.all(
          color: _borderBlue.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 46,
            color: Color(0xFF868DA6),
          ),
          SizedBox(height: 12),
          Text(
            'No reports found',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: _textGrey,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'There are no issue reports under this filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Roboto Condensed',
              fontSize: 13,
              color: Color(0xFF858585),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final IssueReportModel report;
  final VoidCallback onTap;

  const _AdminReportCard({
    required this.report,
    required this.onTap,
  });

  Color get _statusColor {
    switch (report.status) {
      case IssueReportStatus.newReport:
        return const Color(0xFF2A77B4);
      case IssueReportStatus.inReview:
        return const Color(0xFFE6A817);
      case IssueReportStatus.resolved:
        return const Color(0xFF2E9E4F);
      case IssueReportStatus.rejected:
        return const Color(0xFFE51717);
    }
  }

  IconData get _categoryIcon {
    final category = report.category.toLowerCase();

    if (category.contains('navigation')) {
      return Icons.navigation_outlined;
    }

    if (category.contains('booking')) {
      return Icons.calendar_month_outlined;
    }

    if (category.contains('account')) {
      return Icons.person_outline;
    }

    if (category.contains('map')) {
      return Icons.map_outlined;
    }

    return Icons.report_problem_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'd MMM yyyy, HH:mm',
    ).format(report.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(
            color: const Color(0xFF2A77B4),
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon,
                    color: _statusColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF2A77B4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Roboto Condensed',
                          fontSize: 12,
                          color: Color(0xFF8A8F9D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _StatusBadge(
                  status: report.status,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                report.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto Condensed',
                  fontSize: 14,
                  height: 1.35,
                  color: Color(0xFF4D4D4D),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  'Review Report',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: _statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IssueReportStatus status;

  const _StatusBadge({
    required this.status,
  });

  Color get _color {
    switch (status) {
      case IssueReportStatus.newReport:
        return const Color(0xFF2A77B4);
      case IssueReportStatus.inReview:
        return const Color(0xFFE6A817);
      case IssueReportStatus.resolved:
        return const Color(0xFF2E9E4F);
      case IssueReportStatus.rejected:
        return const Color(0xFFE51717);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Roboto Flex',
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: Color(0xFF424242),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final Color Function(T) itemColor;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.itemColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF2A77B4),
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF868DA6),
          ),
          items: items.map(
            (item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: itemColor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      itemLabel(item),
                      style: const TextStyle(
                        fontFamily: 'Roboto Flex',
                        fontSize: 14,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2B38A7),
              Color(0xFFFF2B00),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}