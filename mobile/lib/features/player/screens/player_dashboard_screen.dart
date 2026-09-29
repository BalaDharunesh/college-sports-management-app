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
        title: Row(
          children: [
            const Icon(Icons.sports_rounded, size: 20),
            const SizedBox(width: 8),
            Text('SportSync - Student Portal'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (playerProvider.unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text(
                      '${playerProvider.unreadNotificationsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
                    // Welcome Player Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFF0D9488)],
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
                                  'OFFICIAL ATHLETE',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(user?.sportName ?? 'Sports', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'Player Name',
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg No: ${user?.registerNumber ?? "22CS045"} • Jersey #${user?.jerseyNumber ?? "18"}',
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          ),
                          Text(
                            'Position: ${user?.position ?? "Top-Order Batsman"}',
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.8)),
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
