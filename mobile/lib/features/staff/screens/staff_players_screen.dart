import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../../captain/providers/captain_provider.dart';

class StaffPlayersScreen extends StatefulWidget {
  const StaffPlayersScreen({super.key});

  @override
  State<StaffPlayersScreen> createState() => _StaffPlayersScreenState();
}

class _StaffPlayersScreenState extends State<StaffPlayersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.role == 'CAPTAIN') {
        final capProv = Provider.of<CaptainProvider>(context, listen: false);
        if (capProv.players.isEmpty) {
          capProv.fetchCaptainDashboardData();
        }
      } else {
        final staffProv = Provider.of<StaffProvider>(context, listen: false);
        if (staffProv.players.isEmpty) {
          staffProv.fetchStaffDashboardData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCaptain = authProvider.user?.role == 'CAPTAIN';

    final List<dynamic> rawPlayers;
    final bool isLoading;

    if (isCaptain) {
      final captainProvider = Provider.of<CaptainProvider>(context);
      rawPlayers = captainProvider.players;
      isLoading = captainProvider.isLoading;
    } else {
      final staffProvider = Provider.of<StaffProvider>(context);
      rawPlayers = staffProvider.players;
      isLoading = staffProvider.isLoading;
    }

    final players = rawPlayers.where((p) {
      if (_searchQuery.isEmpty) return true;
      final name = (p['name'] ?? '').toString().toLowerCase();
      final reg = (p['register_number'] ?? '').toString().toLowerCase();
      final dept = (p['department'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || reg.contains(query) || dept.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Players'),
        actions: isCaptain
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  onPressed: () => context.push('/staff/create-player'),
                ),
              ],
      ),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading players...')
          : RefreshIndicator(
              onRefresh: () async {
                if (isCaptain) {
                  await Provider.of<CaptainProvider>(context, listen: false).fetchCaptainDashboardData();
                } else {
                  await Provider.of<StaffProvider>(context, listen: false).fetchStaffDashboardData();
                }
              },
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search by player name, register number, or department...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: players.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              EmptyState(
                                icon: Icons.people_outline,
                                title: 'No Players Found',
                                message: 'No players match your search filter or no team players registered yet.',
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final isActive = player['player_active'] == 1 || player['is_active'] == 1;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
                                    child: Text(
                                      player['jersey_number'] != null
                                          ? '#${player['jersey_number']}'
                                          : (player['name'] != null && player['name'].toString().isNotEmpty
                                              ? player['name'].toString()[0].toUpperCase()
                                              : '?'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    player['name'] ?? 'Unnamed Player',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${player['register_number'] ?? "N/A"} • ${player['department'] ?? "N/A"} (${player['academic_year'] ?? "N/A"})\nPosition: ${player['position'] ?? "Unspecified"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'deactivate') {
                                        if (isCaptain) {
                                          Provider.of<CaptainProvider>(context, listen: false).togglePlayerDeactivation(player['player_id']);
                                        } else {
                                          Provider.of<StaffProvider>(context, listen: false).togglePlayerDeactivation(player['player_id']);
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'deactivate',
                                        child: Text(isActive ? 'Deactivate Player' : 'Reactivate Player'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
