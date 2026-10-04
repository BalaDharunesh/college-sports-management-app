import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/captain_provider.dart';

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

class CaptainTrainingScreen extends StatelessWidget {
  const CaptainTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context);
    final schedules = captainProvider.trainingSchedules;

    final upcomingSchedules = <dynamic>[];
    final pastSchedules = <dynamic>[];

    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final todayStr = '$year-$month-$day';

    for (var ts in schedules) {
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
          title: const Text('Training & Net Practice'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => captainProvider.fetchCaptainDashboardData(),
            ),
          ],
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
        body: RefreshIndicator(
          onRefresh: captainProvider.fetchCaptainDashboardData,
          child: TabBarView(
            children: [
              _buildList(upcomingSchedules, isPast: false),
              _buildList(pastSchedules, isPast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, {required bool isPast}) {
    if (list.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: EmptyState(
            icon: Icons.fitness_center_outlined,
            title: isPast ? 'No Past Training Sessions' : 'No Upcoming Training Sessions',
            message: isPast
                ? 'No past training schedules recorded.'
                : 'No net practice or fitness training scheduled by staff yet.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final ts = list[index];
        final isCancelled = ts['is_cancelled'] == 1 || ts['is_cancelled'] == true;
        final titleFormatted = formatText(ts['title'] ?? 'Training Session');
        final descFormatted = formatText(ts['description']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: isPast ? AppColors.textSecondary : AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              titleFormatted,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: isCancelled ? 'CANCELLED' : (isPast ? 'COMPLETED' : 'SCHEDULED')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${ts['training_date']} (${ts['start_time']} - ${ts['end_time']})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Venue: ${ts['venue']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (descFormatted.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    descFormatted,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
