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
import '../providers/staff_provider.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffProvider>(context, listen: false).fetchStaffDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final staffProvider = Provider.of<StaffProvider>(context);

    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 20),
            const SizedBox(width: 8),
            Text('Staff Portal - ${user?.sportName ?? "Sports"}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => staffProvider.fetchStaffDashboardData(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to sign out from SportSync?'),
                  actions: [
                    TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        ctx.pop();
                        authProvider.logout();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: staffProvider.isLoading
          ? const LoadingIndicator(message: 'Loading Staff Dashboard...')
          : RefreshIndicator(
              onRefresh: staffProvider.fetchStaffDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Staff Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
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
                                  'OFFICIAL STAFF',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                user?.sportName ?? 'Sports',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'Staff Member',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Assigned Team: ${user?.teamName ?? "Strikers XI"}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Summary Metrics Grid
                    Text(
                      'Overview & Approvals',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
                          title: 'Active Players',
                          value: '${staffProvider.totalActivePlayers}',
                          icon: Icons.people_alt_outlined,
                          iconColor: AppColors.secondary,
                          onTap: () => context.push('/staff/players'),
                        ),
                        DashboardCard(
                          title: 'Pending Selections',
                          value: '${staffProvider.pendingSelectionsCount}',
                          icon: Icons.how_to_reg_outlined,
                          iconColor: AppColors.warning,
                          onTap: () => context.push('/staff/selections'),
                        ),
                        DashboardCard(
                          title: 'Pending OD Claims',
                          value: '${staffProvider.pendingOdCount}',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.accent,
                          onTap: () => context.push('/staff/od-approvals'),
                        ),
                        DashboardCard(
                          title: 'Pending TA/DA',
                          value: '${staffProvider.pendingTadaCount}',
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.primary,
                          onTap: () => context.push('/staff/tada-approvals'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Management Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionChip(
                            context,
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'Add Player',
                            onTap: () => context.push('/staff/create-player'),
                          ),
                          _buildActionChip(
                            context,
                            icon: Icons.event_available_outlined,
                            label: 'Create Match',
                            onTap: () => context.push('/staff/create-match'),
                          ),
                          _buildActionChip(
                            context,
                            icon: Icons.fitness_center_outlined,
                            label: 'Schedule Training',
                            onTap: () => context.push('/staff/training'),
                          ),
                          _buildActionChip(
                            context,
                            icon: Icons.feedback_outlined,
                            label: 'Captain Feedback',
                            onTap: () => context.push('/staff/feedback'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Matches Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Matches',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/staff/matches'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    staffProvider.matches.isEmpty
                        ? const EmptyState(
                            icon: Icons.sports_cricket_outlined,
                            title: 'No Matches Scheduled',
                            message: 'Create a match to manage squad selections and publish results.',
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: staffProvider.matches.take(3).length,
                            itemBuilder: (context, index) {
                              final match = staffProvider.matches[index];
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
                                          Expanded(
                                            child: Text(
                                              match['title'],
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          StatusBadge(status: match['status']),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.shield_outlined, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text('vs ${match['opponent_name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text('${match['match_date']} at ${match['start_time']}'),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(match['venue'], maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
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

  Widget _buildActionChip(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.primary),
        label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: onTap,
      ),
    );
  }
}
