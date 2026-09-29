import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/player_provider.dart';

class PlayerMatchesScreen extends StatelessWidget {
  const PlayerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final matches = playerProvider.matches;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches & Selection Status')),
      body: matches.isEmpty
          ? const EmptyState(
              icon: Icons.sports_cricket_outlined,
              title: 'No Matches Scheduled',
              message: 'Check back later for upcoming tournament match schedules.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final isCompleted = match['status'] == 'COMPLETED';

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
                            StatusBadge(status: match['status']),
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
