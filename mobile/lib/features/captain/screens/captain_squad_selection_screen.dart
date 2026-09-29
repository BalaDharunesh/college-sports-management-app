import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/captain_provider.dart';

class CaptainSquadSelectionScreen extends StatefulWidget {
  const CaptainSquadSelectionScreen({super.key});

  @override
  State<CaptainSquadSelectionScreen> createState() => _CaptainSquadSelectionScreenState();
}

class _CaptainSquadSelectionScreenState extends State<CaptainSquadSelectionScreen> {
  int? _selectedMatchId;
  final Set<int> _selectedPlayerIds = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context);
    final matches = captainProvider.matches.where((m) => m['status'] == 'SCHEDULED').toList();
    final players = captainProvider.players.where((p) => p['player_active'] == 1 || p['is_active'] == 1).toList();

    if (_selectedMatchId == null && matches.isNotEmpty) {
      _selectedMatchId = matches.first['id'];
    }

    final currentMatch = matches.firstWhere(
      (m) => m['id'] == _selectedMatchId,
      orElse: () => matches.isNotEmpty ? matches.first : {},
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Match Squad Selection')),
      body: matches.isEmpty
          ? const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No Active Match for Selection',
              message: 'There are currently no scheduled matches available for squad selection.',
            )
          : Column(
              children: [
                // Match Selector Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Match:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedMatchId,
                        isExpanded: true,
                        items: matches.map<DropdownMenuItem<int>>((m) {
                          return DropdownMenuItem<int>(
                            value: m['id'],
                            child: Text('${m['title']} vs ${m['opponent_name']} (${m['match_date']})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMatchId = val;
                            _selectedPlayerIds.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Active Team Players:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${_selectedPlayerIds.length} Selected',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: players.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Active Players',
                          message: 'Add players to your team before selecting match squad.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final pId = player['player_id'];
                            final isSelected = _selectedPlayerIds.contains(pId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: CheckboxListTile(
                                value: isSelected,
                                activeColor: AppColors.secondary,
                                title: Text(player['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                subtitle: Text('${player['register_number']} • ${player['department']}\nPosition: ${player['position'] ?? "N/A"}'),
                                secondary: CircleAvatar(
                                  backgroundColor: isSelected ? AppColors.secondary : AppColors.primary,
                                  child: Text(
                                    player['jersey_number'] != null ? '#${player['jersey_number']}' : player['name'][0],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedPlayerIds.add(pId);
                                    } else {
                                      _selectedPlayerIds.remove(pId);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),

                // Submit Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, -4))],
                  ),
                  child: CustomButton(
                    text: 'Submit Squad Selection for Approval (${_selectedPlayerIds.length})',
                    isLoading: _isSubmitting,
                    onPressed: _selectedPlayerIds.isEmpty || _selectedMatchId == null
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            final success = await captainProvider.submitSquadSelection(
                              _selectedMatchId!,
                              _selectedPlayerIds.toList(),
                            );
                            if (!mounted) return;
                            setState(() => _isSubmitting = false);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Squad selection submitted to staff for approval! Status set to PENDING.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(captainProvider.error ?? 'Failed to submit selection.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
    );
  }
}
