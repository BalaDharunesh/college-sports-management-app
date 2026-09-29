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
            Text('Captain Portal - ${user?.sportName ?? "Sports"}'),
          ],
        ),
        actions: [
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
                    // Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'TEAM CAPTAIN',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(user?.sportName ?? 'Cricket', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'Captain Name',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg No: ${user?.registerNumber ?? "21CS001"} • ${user?.teamName ?? "Team"}',
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.85)),
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

                    // Matches
                    Text('Upcoming Matches & Squad Selections', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    captainProvider.matches.isEmpty
                        ? const EmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'No Upcoming Matches',
                            message: 'No matches scheduled for your team yet.',
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: captainProvider.matches.length,
                            itemBuilder: (context, index) {
                              final match = captainProvider.matches[index];
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
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.push('/captain/squad-selection'),
                                          icon: const Icon(Icons.touch_app_outlined, size: 16),
                                          label: const Text('Manage Match Squad'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
