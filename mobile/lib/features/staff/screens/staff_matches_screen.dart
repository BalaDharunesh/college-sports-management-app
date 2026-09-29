import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';

class StaffMatchesScreen extends StatelessWidget {
  const StaffMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final matches = staffProvider.matches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Schedule & Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/staff/create-match'),
          ),
        ],
      ),
      body: matches.isEmpty
          ? const EmptyState(
              icon: Icons.sports_cricket_outlined,
              title: 'No Matches Found',
              message: 'Click + to schedule a new inter-college sports match.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final isCompleted = match['status'] == 'COMPLETED';

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
                            Expanded(
                              child: Text(
                                match['title'],
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(status: match['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${match['team_name']} vs ${match['opponent_name']}',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${match['match_date']} at ${match['start_time']}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(match['venue'], maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        if (isCompleted) ...[
                          const Divider(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Result: ${match['outcome']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    if (match['result_remarks'] != null)
                                      Text(match['result_remarks'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                Text(
                                  '${match['team_score']} - ${match['opponent_score']}',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final teamScoreCtrl = TextEditingController();
                                  final oppScoreCtrl = TextEditingController();
                                  final remarksCtrl = TextEditingController();
                                  String outcome = 'WIN';

                                  showDialog(
                                    context: context,
                                    builder: (ctx) => StatefulBuilder(
                                      builder: (context, setDialogState) => AlertDialog(
                                        title: const Text('Update Match Result'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: teamScoreCtrl,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(labelText: 'Team Score'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: TextField(
                                                    controller: oppScoreCtrl,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(labelText: 'Opponent Score'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            DropdownButtonFormField<String>(
                                              value: outcome,
                                              items: ['WIN', 'LOSS', 'DRAW'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                              onChanged: (v) => setDialogState(() => outcome = v!),
                                              decoration: const InputDecoration(labelText: 'Outcome'),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: remarksCtrl,
                                              decoration: const InputDecoration(labelText: 'Remarks / Highlights'),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              final tScore = int.tryParse(teamScoreCtrl.text) ?? 0;
                                              final oScore = int.tryParse(oppScoreCtrl.text) ?? 0;
                                              final success = await staffProvider.submitResult(
                                                match['id'], tScore, oScore, outcome, remarksCtrl.text
                                              );
                                              if (context.mounted && success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Match result published!'), backgroundColor: AppColors.success),
                                                );
                                              }
                                            },
                                            child: const Text('Publish Result'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.scoreboard_outlined, size: 16),
                                label: const Text('Enter Result'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
