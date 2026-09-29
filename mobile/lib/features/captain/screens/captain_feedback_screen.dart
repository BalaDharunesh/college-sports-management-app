import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/captain_provider.dart';

class CaptainFeedbackScreen extends StatefulWidget {
  const CaptainFeedbackScreen({super.key});

  @override
  State<CaptainFeedbackScreen> createState() => _CaptainFeedbackScreenState();
}

class _CaptainFeedbackScreenState extends State<CaptainFeedbackScreen> {
  void _openFeedbackModal(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context, listen: false);
    final matches = captainProvider.matches;

    int? selectedMatchId = matches.isNotEmpty ? matches.first['id'] : null;
    String category = 'Match Organization';
    final feedbackCtrl = TextEditingController();
    final suggestionsCtrl = TextEditingController();

    final categories = [
      'Match Organization',
      'Venue',
      'Transportation',
      'Equipment',
      'Scheduling',
      'General feedback'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Submit Match Feedback to Staff', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedMatchId,
                decoration: const InputDecoration(labelText: 'Match'),
                items: matches.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['title']))).toList(),
                onChanged: (v) => setModalState(() => selectedMatchId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Feedback Category'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModalState(() => category = v!),
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: feedbackCtrl, label: 'Feedback Details *', hint: 'Provide details regarding match venue, arrangements, etc.', maxLines: 3),
              const SizedBox(height: 12),
              CustomTextField(controller: suggestionsCtrl, label: 'Suggestions', hint: 'Suggestions for future tournaments'),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Send Feedback to Sports Staff',
                onPressed: () async {
                  if (selectedMatchId == null || feedbackCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  final success = await captainProvider.submitFeedback({
                    'matchId': selectedMatchId,
                    'category': category,
                    'feedbackText': feedbackCtrl.text,
                    'suggestions': suggestionsCtrl.text,
                  });
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Match feedback sent to sports staff!'), backgroundColor: AppColors.success),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context);
    final feedbackList = captainProvider.feedbackList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Feedback & Responses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: () => _openFeedbackModal(context),
          ),
        ],
      ),
      body: feedbackList.isEmpty
          ? const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No Feedback Submitted',
              message: 'Click + to submit feedback to sports staff after matches.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final fb = feedbackList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${fb['category']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(fb['feedback_text']),
                        if (fb['staff_response'] != null) ...[
                          const Divider(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Staff Response:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 12)),
                                Text(fb['staff_response']),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
