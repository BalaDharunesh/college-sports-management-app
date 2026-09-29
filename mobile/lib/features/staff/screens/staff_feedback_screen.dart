import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/staff_provider.dart';

class StaffFeedbackScreen extends StatelessWidget {
  const StaffFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final feedbackList = staffProvider.feedbackList;

    return Scaffold(
      appBar: AppBar(title: const Text('Captain Match Feedback')),
      body: feedbackList.isEmpty
          ? const EmptyState(
              icon: Icons.feedback_outlined,
              title: 'No Captain Feedback',
              message: 'Captains have not submitted match feedback entries yet.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final fb = feedbackList[index];
                final hasResponse = fb['staff_response'] != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category: ${fb['category']}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              fb['captain_name'] ?? 'Captain',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Match: ${fb['match_title'] ?? "Match"}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text('Feedback: ${fb['feedback_text']}'),
                        if (fb['suggestions'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Suggestions: ${fb['suggestions']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        if (hasResponse) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Staff Response:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                                const SizedBox(height: 4),
                                Text(fb['staff_response'], style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ] else ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final responseCtrl = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Respond to Captain Feedback'),
                                    content: TextField(
                                      controller: responseCtrl,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Official Staff Response',
                                        hintText: 'Action plan or administrative response...',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (responseCtrl.text.trim().isEmpty) return;
                                          Navigator.pop(ctx);
                                          final success = await staffProvider.respondFeedback(fb['id'], responseCtrl.text);
                                          if (context.mounted && success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Response submitted!'), backgroundColor: AppColors.success),
                                            );
                                          }
                                        },
                                        child: const Text('Submit Response'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.reply_outlined, size: 16),
                              label: const Text('Respond'),
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
