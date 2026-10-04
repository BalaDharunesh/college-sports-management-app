import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_card.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/captain_provider.dart';
import '../../../core/widgets/view_squad_modal.dart';

class CaptainDashboardScreen extends StatefulWidget {
  const CaptainDashboardScreen({super.key});

  @override
  State<CaptainDashboardScreen> createState() => _CaptainDashboardScreenState();
}

class _CaptainDashboardScreenState extends State<CaptainDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CaptainProvider>(context, listen: false).fetchCaptainDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final captainProvider = Provider.of<CaptainProvider>(context);

    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.stars_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Captain Portal - ${user?.sportName ?? "Sports"}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => captainProvider.fetchCaptainDashboardData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: captainProvider.isLoading
          ? const LoadingIndicator(message: 'Loading Captain Dashboard...')
          : RefreshIndicator(
              onRefresh: captainProvider.fetchCaptainDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CIT Style Profile Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.avatarBg,
                            child: Icon(Icons.person, size: 36, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (user?.name ?? 'Rahul Sharma').toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.registerNumber ?? '21CS001',
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'CAPTAIN • ${user?.sportName ?? "Cricket"} (${user?.teamName ?? "Strikers XI"})',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metric Cards
                    Text('Captain Overview', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        DashboardCard(
                          title: 'Team Squad',
                          value: '${captainProvider.players.length}',
                          icon: Icons.groups_outlined,
                          iconColor: AppColors.secondary,
                          onTap: () => context.push('/captain/team'),
                        ),
                        DashboardCard(
                          title: 'Upcoming Matches',
                          value: '${captainProvider.matches.where((m) => m['status'] == 'SCHEDULED').length}',
                          icon: Icons.sports_cricket_outlined,
                          iconColor: AppColors.primary,
                          onTap: () => context.push('/captain/squad-selection'),
                        ),
                        DashboardCard(
                          title: 'Training Sessions',
                          value: '${captainProvider.trainingSchedules.where((t) => t['is_cancelled'] != 1 && t['is_cancelled'] != true && (t['training_date']?.toString() ?? '').compareTo(DateTime.now().toIso8601String().split('T')[0]) >= 0).length}',
                          icon: Icons.fitness_center_outlined,
                          iconColor: AppColors.success,
                          onTap: () => context.push('/captain/training'),
                        ),
                        DashboardCard(
                          title: 'OD Requests',
                          value: '${captainProvider.odRequests.length}',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.accent,
                          onTap: () => context.push('/captain/od-request'),
                        ),
                        DashboardCard(
                          title: 'TA/DA Claims',
                          value: '${captainProvider.tadaRequests.length}',
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.warning,
                          onTap: () => context.push('/captain/tada-request'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text('Management & Submissions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChip(context, icon: Icons.how_to_reg_outlined, label: 'Select Squad', onTap: () => context.push('/captain/squad-selection')),
                          _buildChip(context, icon: Icons.assignment_turned_in_outlined, label: 'Submit OD Claim', onTap: () => context.push('/captain/od-request')),
                          _buildChip(context, icon: Icons.monetization_on_outlined, label: 'Submit TA/DA', onTap: () => context.push('/captain/tada-request')),
                          _buildChip(context, icon: Icons.rate_review_outlined, label: 'Match Feedback', onTap: () => context.push('/captain/feedback')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Matches
                    Text('Upcoming Matches & Squad Selections', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    () {
                      final todayStr = DateTime.now().toIso8601String().split('T')[0];
                      final upcoming = captainProvider.matches.where((m) {
                        final status = m['status']?.toString().toUpperCase() ?? '';
                        if (status == 'COMPLETED') return false;
                        final dateStr = m['match_date']?.toString() ?? '';
                        if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) return false;
                        return true;
                      }).toList();

                      if (upcoming.isEmpty) {
                        return const EmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'No Upcoming Matches',
                          message: 'No matches scheduled after current date.',
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcoming.length,
                        itemBuilder: (context, index) {
                          final match = upcoming[index];
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
                                      Expanded(child: Text(match['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16))),
                                      StatusBadge(status: match['status']),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('vs ${match['opponent_name']} • Date: ${match['match_date']}'),
                                  const SizedBox(height: 12),
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
                                      OutlinedButton.icon(
                                        onPressed: () => context.push('/captain/squad-selection'),
                                        icon: const Icon(Icons.touch_app_outlined, size: 16),
                                        label: const Text('Manage Squad'),
                                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }(),

                    // Completed Matches & Results
                    const SizedBox(height: 24),
                    Text('Completed Matches & Results', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final todayStr = DateTime.now().toIso8601String().split('T')[0];
                        final completed = captainProvider.matches.where((m) {
                          final status = m['status']?.toString().toUpperCase() ?? '';
                          if (status == 'COMPLETED') return true;
                          final dateStr = m['match_date']?.toString() ?? '';
                          if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) return true;
                          return false;
                        }).toList();

                        if (completed.isEmpty) {
                          return const EmptyState(
                            icon: Icons.task_alt_outlined,
                            title: 'No Completed Matches',
                            message: 'Finished matches prior to current date will appear here.',
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: completed.length,
                          itemBuilder: (context, index) {
                            final match = completed[index];
                            final String scoreText = match['team_score'] != null && match['opponent_score'] != null
                                ? 'Result: ${match['team_score']} - ${match['opponent_score']} (${match['outcome'] ?? ""})'
                                : 'Match Completed';

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
                                        Expanded(child: Text(match['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16))),
                                        const StatusBadge(status: 'COMPLETED'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('vs ${match['opponent_name']} • Date: ${match['match_date']}'),
                                    const SizedBox(height: 6),
                                    Text(scoreText, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary)),
                                    if (match['result_remarks'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Remarks: ${match['result_remarks']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChip(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.secondary),
        label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.secondary)),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: onTap,
      ),
    );
  }
}
