import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/staff_provider.dart';

class StaffPlayersScreen extends StatefulWidget {
  const StaffPlayersScreen({super.key});

  @override
  State<StaffPlayersScreen> createState() => _StaffPlayersScreenState();
}

class _StaffPlayersScreenState extends State<StaffPlayersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final players = staffProvider.players.where((p) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => context.push('/staff/create-player'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by player name, register number, or department...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: players.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Players Found',
                    message: 'No players match your search filter or no team players registered yet.',
                  )
                : ListView.builder(
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
                              player['jersey_number'] != null ? '#${player['jersey_number']}' : player['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            player['name'],
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${player['register_number'] ?? "N/A"} • ${player['department']} (${player['academic_year']})\nPosition: ${player['position'] ?? "Unspecified"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'deactivate') {
                                staffProvider.togglePlayerDeactivation(player['player_id']);
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
    );
  }
}
