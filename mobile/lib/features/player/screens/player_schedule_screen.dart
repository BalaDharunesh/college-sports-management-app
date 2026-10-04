import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/player_provider.dart';

String formatText(String? text) {
  if (text == null || text.trim().isEmpty) return '';
  var t = text.trim();
  t = t.replaceAll(RegExp(r'\bfeilding\b', caseSensitive: false), 'Fielding');
  t = t.replaceAll(RegExp(r'\btactice\b', caseSensitive: false), 'Tactics');
  t = t.replaceAll(RegExp(r'\bbrainstrom\b', caseSensitive: false), 'Brainstorm');
  t = t.replaceAll(RegExp(r'\bseesion\b', caseSensitive: false), 'Session');
  t = t.replaceAll(RegExp(r'\bshettle\b', caseSensitive: false), 'Shuttle');

  if (t == t.toLowerCase()) {
    t = t.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
  return t;
}

class PlayerScheduleScreen extends StatelessWidget {
  const PlayerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final training = playerProvider.trainingSchedules;

    final upcomingSchedules = <dynamic>[];
    final pastSchedules = <dynamic>[];

    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final todayStr = '$year-$month-$day';

    for (var ts in training) {
      if (ts == null) continue;
      final dateStr = (ts['training_date'] ?? '').toString().trim().split(' ')[0];
      if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) {
        pastSchedules.add(ts);
      } else {
        upcomingSchedules.add(ts);
      }
    }

    upcomingSchedules.sort((a, b) => (a['training_date'] ?? '').toString().compareTo((b['training_date'] ?? '').toString()));
    pastSchedules.sort((a, b) => (b['training_date'] ?? '').toString().compareTo((a['training_date'] ?? '').toString()));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Training & Practice Schedule'),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'Upcoming Training (${upcomingSchedules.length})'),
              Tab(text: 'Past Training (${pastSchedules.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(upcomingSchedules, isPast: false),
            _buildList(pastSchedules, isPast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, {required bool isPast}) {
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.fitness_center_outlined,
        title: isPast ? 'No Past Practice Sessions' : 'No Upcoming Practice Sessions',
        message: isPast
            ? 'No past practice sessions recorded.'
            : 'Staff has not scheduled any upcoming practice sessions yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ts = list[index];
        final titleFormatted = formatText(ts['title'] ?? 'Practice Session');
        final descFormatted = formatText(ts['description']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPast ? AppColors.textSecondary : AppColors.accent,
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
            ),
            title: Text(titleFormatted, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Date: ${ts['training_date']} (${ts['start_time']} - ${ts['end_time']})\nVenue: ${ts['venue']}${descFormatted.isNotEmpty ? "\n$descFormatted" : ""}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
