import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';
import '../../../core/widgets/view_squad_modal.dart';

class StaffMatchesScreen extends StatelessWidget {
  const StaffMatchesScreen({super.key});

  void _showResultDialog(BuildContext context, StaffProvider staffProvider, Map<String, dynamic> match) {
    final teamScoreCtrl = TextEditingController(text: match['team_score'] != null ? match['team_score'].toString() : '');
    final oppScoreCtrl = TextEditingController(text: match['opponent_score'] != null ? match['opponent_score'].toString() : '');
    final remarksCtrl = TextEditingController(text: match['result_remarks']?.toString() ?? '');
    String outcome = match['outcome'] != null ? match['outcome'].toString() : 'WIN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(match['status'] == 'COMPLETED' ? 'Edit Match Result' : 'Enter Match Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: teamScoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Team Score',
                        hintText: 'e.g. 185 or 185/4',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: oppScoreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Opponent Score',
                        hintText: 'e.g. 162 or 162/10',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ['WIN', 'LOSS', 'DRAW'].contains(outcome) ? outcome : 'WIN',
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
                final tScore = teamScoreCtrl.text.trim();
                final oScore = oppScoreCtrl.text.trim();
                if (tScore.isEmpty || oScore.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter scores for both teams.'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final success = await staffProvider.submitResult(
                  match['id'], tScore, oScore, outcome, remarksCtrl.text.trim()
                );
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match result saved!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Save Result'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final matches = staffProvider.matches;

    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final upcomingMatches = matches.where((m) {
      final status = m['status']?.toString().toUpperCase() ?? '';
      if (status == 'COMPLETED') return false;
      final dateStr = m['match_date']?.toString() ?? '';
      if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) return false;
      return true;
    }).toList();

    final completedMatches = matches.where((m) {
      final status = m['status']?.toString().toUpperCase() ?? '';
      if (status == 'COMPLETED') return true;
      final dateStr = m['match_date']?.toString() ?? '';
      if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) return true;
      return false;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Schedule & Results'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/staff/create-match'),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'Upcoming (${upcomingMatches.length})'),
              Tab(text: 'Completed (${completedMatches.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMatchList(context, staffProvider, upcomingMatches, isUpcoming: true),
            _buildMatchList(context, staffProvider, completedMatches, isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(BuildContext context, StaffProvider staffProvider, List<dynamic> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return EmptyState(
        icon: isUpcoming ? Icons.event_available_outlined : Icons.task_alt_outlined,
        title: isUpcoming ? 'No Upcoming Matches' : 'No Completed Matches',
        message: isUpcoming
            ? 'No matches scheduled after current date.'
            : 'Finished matches prior to current date will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final match = list[index];
        final isCompleted = !isUpcoming || match['status'] == 'COMPLETED';

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
                    StatusBadge(status: isCompleted ? 'COMPLETED' : match['status']),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Result: ${match['outcome'] ?? "FINISHED"}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              if (match['result_remarks'] != null && match['result_remarks'].toString().isNotEmpty)
                                Text(match['result_remarks'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${match['team_score'] ?? 0} - ${match['opponent_score'] ?? 0}',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: AppColors.primary),
                              tooltip: 'Edit Result',
                              onPressed: () => _showResultDialog(context, staffProvider, match),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => showViewSquadModal(context, match),
                      icon: const Icon(Icons.groups_outlined, size: 16),
                      label: const Text('View Squad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                    if (!isCompleted)
                      OutlinedButton.icon(
                        onPressed: () => _showResultDialog(context, staffProvider, match),
                        icon: const Icon(Icons.scoreboard_outlined, size: 16),
                        label: const Text('Enter Result'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
