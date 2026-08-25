import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../models/legal_document_model.dart';
import '../services/legal_document_service.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    required this.documentKey,
    required this.subtitle,
    super.key,
  });

  final String documentKey;
  final String subtitle;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late Future<LegalDocumentModel> _documentFuture;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  void _loadDocument() {
    _documentFuture = LegalDocumentService().getDocument(widget.documentKey);
  }

  void _retry() {
    setState(_loadDocument);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _CampusSubpageHeader(
              subtitle: widget.subtitle,
              onBack: () {
                Navigator.of(context).maybePop();
              },
              onClose: () {
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: FutureBuilder<LegalDocumentModel>(
                future: _documentFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2A77B4),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 44,
                              color: Color(0xFFB3261E),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to load this document.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final document = snapshot.data!;

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
                    children: [
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF115388),
                        ),
                      ),
                      const SizedBox(height: 22),

                      ..._documentBlocks(document.content),

                      const SizedBox(height: 10),

                      Text(
                        'Last updated: '
                        '${document.updatedAt.toLocal().year}-'
                        '${document.updatedAt.toLocal().month.toString().padLeft(2, '0')}-'
                        '${document.updatedAt.toLocal().day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11.5,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _documentBlocks(String content) {
    final blocks = content.trim().split(RegExp(r'\n\s*\n'));

    final widgets = <Widget>[];

    for (final rawBlock in blocks) {
      final block = rawBlock.trim();

      if (block.isEmpty) {
        continue;
      }

      final lines = block.split('\n');

      final firstLine = lines.first.trim();

      final isHeading = RegExp(r'^\d+\.\s+').hasMatch(firstLine);

      if (isHeading) {
        widgets.add(
          Text(
            firstLine,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A77B4),
            ),
          ),
        );

        if (lines.length > 1) {
          widgets.add(const SizedBox(height: 8));

          widgets.add(
            Text(
              lines.skip(1).join('\n'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF444444),
              ),
            ),
          );
        }

        widgets.add(const SizedBox(height: 24));
      } else {
        widgets.add(
          Text(
            block,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14.5,
              height: 1.55,
              color: Color(0xFF555555),
            ),
          ),
        );

        widgets.add(const SizedBox(height: 26));
      }
    }

    return widgets;
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
                  onPressed: onClose,
                  icon: SvgPicture.asset(AppAssets.closeButton, width: 23),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
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
