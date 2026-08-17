import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _issueController = TextEditingController();

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  void _submitIssue() {
    final text = _issueController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue first.')),
      );
      return;
    }

    _issueController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Issue report prepared successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Help & Feedback',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w800,
            color: Color(0xFF38358E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A77B4),
            ),
          ),

          const SizedBox(height: 12),

          const _FaqTile(
            question: 'How do I start navigation?',
            answer:
                'Select your current location and destination, '
                'then start the route from the CampusGO home screen.',
          ),
          const _FaqTile(
            question: 'Why does CampusGO use QR codes?',
            answer:
                'QR checkpoints can help establish a known indoor '
                'starting location where GPS may not be reliable.',
          ),
          const _FaqTile(
            question: 'Can guests use CampusGO?',
            answer:
                'Yes. Guests may access permitted public navigation '
                'and timetable features without creating an account.',
          ),

          const SizedBox(height: 28),

          const Text(
            'Report an Issue',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A77B4),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _issueController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Describe the problem you experienced...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _submitIssue,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38358E),
              ),
              child: const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(height: 1.4, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
