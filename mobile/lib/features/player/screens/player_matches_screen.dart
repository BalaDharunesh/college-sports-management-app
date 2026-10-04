import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/player_provider.dart';

import '../../../core/widgets/view_squad_modal.dart';

class PlayerMatchesScreen extends StatelessWidget {
  const PlayerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final matches = playerProvider.matches;

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
          title: const Text('Matches & Selection Status'),
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
            _buildMatchList(upcomingMatches, isUpcoming: true),
            _buildMatchList(completedMatches, isUpcoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(List<dynamic> list, {required bool isUpcoming}) {
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
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(match['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16))),
                    StatusBadge(status: isCompleted ? 'COMPLETED' : match['status']),
                  ],
                ),
                const SizedBox(height: 6),
                Text('vs ${match['opponent_name']} • ${match['match_date']} (${match['start_time']})'),
                Text('Venue: ${match['venue']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Official Selection Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    StatusBadge(status: match['my_selection_status'] ?? 'NOT_SELECTED'),
                  ],
                ),
                if (isCompleted && match['outcome'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Result: ${match['team_name']} ${match['outcome']} (${match['team_score']} - ${match['opponent_score']})',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => showViewSquadModal(context, match),
                    icon: const Icon(Icons.groups_outlined, size: 16),
                    label: const Text('View Squad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
