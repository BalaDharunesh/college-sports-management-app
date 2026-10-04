import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/player_provider.dart';

class PlayerDashboardScreen extends StatefulWidget {
  const PlayerDashboardScreen({super.key});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlayerProvider>(context, listen: false).fetchPlayerDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);

    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_rounded, size: 20),
            SizedBox(width: 8),
            Text('SportSync - Student Portal'),
          ],
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/notifications'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 24),
                  if (playerProvider.unreadNotificationsCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              '${playerProvider.unreadNotificationsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: playerProvider.isLoading
          ? const LoadingIndicator(message: 'Loading Student Dashboard...')
          : RefreshIndicator(
              onRefresh: playerProvider.fetchPlayerDashboardData,
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
                            child: Icon(Icons.person, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (user?.name ?? 'Player Name').toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.registerNumber ?? '22CS045',
                                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ATHLETE • ${user?.sportName ?? "Sports"} • Jersey #${user?.jerseyNumber ?? "18"}',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Next Match Highlight Card
                    Text('Next Upcoming Match', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    playerProvider.nextMatch != null
                        ? Card(
                            elevation: 2,
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
                                          playerProvider.nextMatch!['title'],
                                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      StatusBadge(status: playerProvider.nextMatch!['my_selection_status'] ?? 'SCHEDULED'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'vs ${playerProvider.nextMatch!['opponent_name']}',
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${playerProvider.nextMatch!['match_date']} at ${playerProvider.nextMatch!['start_time']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${playerProvider.nextMatch!['venue']}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const EmptyState(
                            icon: Icons.event_available_outlined,
                            title: 'No Immediate Matches',
                            message: 'Enjoy your rest! Check back later for match schedules.',
                          ),
                    const SizedBox(height: 20),

                    // Next Training Session Highlight
                    Text('Next Net Practice / Training', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    playerProvider.nextTraining != null
                        ? Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.accent,
                                child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
                              ),
                              title: Text(playerProvider.nextTraining!['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${playerProvider.nextTraining!['training_date']} (${playerProvider.nextTraining!['start_time']} - ${playerProvider.nextTraining!['end_time']})\nVenue: ${playerProvider.nextTraining!['venue']}',
                              ),
                            ),
                          )
                        : const EmptyState(
                            icon: Icons.fitness_center_outlined,
                            title: 'No Training Scheduled',
                            message: 'No upcoming net practice sessions.',
                          ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) context.push('/player/profile');
          if (index == 2) context.push('/player/matches');
          if (index == 3) context.push('/player/schedule');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'My Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket_outlined), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
        ],
      ),
    );
  }
}
