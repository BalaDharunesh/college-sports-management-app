import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';

class StaffSelectionApprovalScreen extends StatelessWidget {
  const StaffSelectionApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final matches = staffProvider.matches;

    // Collect all pending selections across matches
    List<Map<String, dynamic>> pendingItems = [];
    for (var m in matches) {
      if (m['selections'] != null) {
        for (var s in m['selections']) {
          if (s['status'] == 'PENDING') {
            pendingItems.add({
              'match': m,
              'selection': s,
            });
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Squad Selection Approvals')),
      body: pendingItems.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All Squad Selections Reviewed',
              message: 'No pending match player selection submissions awaiting staff approval.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingItems.length,
              itemBuilder: (context, index) {
                final item = pendingItems[index];
                final match = item['match'];
                final sel = item['selection'];

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
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const StatusBadge(status: 'PENDING'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Opponent: ${match['opponent_name']} • Date: ${match['match_date']}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                sel['jersey_number'] != null ? '#${sel['jersey_number']}' : sel['player_name'][0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sel['player_name'],
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${sel['register_number']} • ${sel['department']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Position: ${sel['position'] ?? "Unspecified"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final reasonController = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Reject Selection'),
                                    content: TextField(
                                      controller: reasonController,
                                      decoration: const InputDecoration(
                                        labelText: 'Rejection Reason',
                                        hintText: 'e.g. Fitness concern or academic conflict',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final success = await staffProvider.rejectSelection(sel['id'], reasonController.text);
                                          if (context.mounted && success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Selection rejected.'), backgroundColor: AppColors.error),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                              label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final success = await staffProvider.approveSelection(sel['id']);
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${sel['player_name']} approved! Selection notification sent.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
