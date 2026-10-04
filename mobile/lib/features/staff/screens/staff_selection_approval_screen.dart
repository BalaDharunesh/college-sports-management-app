import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';

class StaffSelectionApprovalScreen extends StatefulWidget {
  const StaffSelectionApprovalScreen({super.key});

  @override
  State<StaffSelectionApprovalScreen> createState() => _StaffSelectionApprovalScreenState();
}

class _StaffSelectionApprovalScreenState extends State<StaffSelectionApprovalScreen> {
  Map<String, dynamic>? _selectedMatch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffProvider>(context, listen: false).fetchStaffDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final matches = staffProvider.matches;

    // Filter matches that have at least 1 pending player selection
    List<Map<String, dynamic>> matchesWithPending = [];
    for (var m in matches) {
      if (m is Map) {
        final selections = m['selections'];
        if (selections is List && selections.any((s) => s is Map && s['status']?.toString() == 'PENDING')) {
          matchesWithPending.add(Map<String, dynamic>.from(m));
        }
      }
    }

    // If a match is currently selected, find its updated data from matches
    Map<String, dynamic>? activeMatch;
    if (_selectedMatch != null) {
      for (var m in matches) {
        if (m is Map && m['id'] == _selectedMatch!['id']) {
          activeMatch = Map<String, dynamic>.from(m);
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeMatch != null
              ? (activeMatch['title']?.toString() ?? 'Match Squad')
              : 'Squad Selection Approvals',
        ),
        leading: activeMatch != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedMatch = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => staffProvider.fetchStaffDashboardData(),
          ),
        ],
      ),
      body: staffProvider.isLoading
          ? const LoadingIndicator(message: 'Loading squad selections...')
          : RefreshIndicator(
              onRefresh: staffProvider.fetchStaffDashboardData,
              child: activeMatch != null
                  ? _buildPlayerApprovalList(context, staffProvider, activeMatch)
                  : _buildMatchList(context, matchesWithPending),
            ),
    );
  }

  // STEP 1: MATCH NAME LIST VIEW
  Widget _buildMatchList(BuildContext context, List<Map<String, dynamic>> matchesWithPending) {
    if (matchesWithPending.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 500,
          child: EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All Squad Selections Reviewed',
            message: 'No pending match player selection submissions awaiting staff approval.',
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: matchesWithPending.length,
      itemBuilder: (context, index) {
        final match = matchesWithPending[index];
        final selections = match['selections'] is List ? (match['selections'] as List) : [];
        final pendingCount = selections.where((s) => s is Map && s['status']?.toString() == 'PENDING').length;

        final String matchTitle = match['title']?.toString() ?? 'Match';
        final String opponentName = match['opponent_name']?.toString() ?? 'Opponent';
        final String matchDate = match['match_date']?.toString() ?? '';
        final String venue = match['venue']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _selectedMatch = match),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_cricket_outlined, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchTitle,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'vs $opponentName',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(matchDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (venue.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  venue,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$pendingCount Pending',
                          style: GoogleFonts.outfit(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // STEP 2: LIST OF PLAYERS FOR APPROVAL VIEW
  Widget _buildPlayerApprovalList(BuildContext context, StaffProvider staffProvider, Map<String, dynamic> match) {
    final selections = match['selections'] is List ? (match['selections'] as List) : [];
    final pendingSelections = selections.where((s) => s is Map && s['status']?.toString() == 'PENDING').toList();

    if (pendingSelections.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          height: 450,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              Text(
                'All Players Reviewed!',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'All squad selection submissions for ${match['title']} have been reviewed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedMatch = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Matches List'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
              ),
            ],
          ),
        ),
      );
    }

    final String matchTitle = match['title']?.toString() ?? 'Match';
    final String opponentName = match['opponent_name']?.toString() ?? 'Opponent';
    final String matchDate = match['match_date']?.toString() ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Match Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      matchTitle,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingSelections.length} Pending Approval',
                      style: GoogleFonts.outfit(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Opponent: $opponentName • Date: $matchDate',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Pending Player Submissions:',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        ...pendingSelections.map((sItem) {
          final sel = sItem is Map ? sItem : {};
          final String playerName = sel['player_name']?.toString() ?? 'Player';
          final String regNumber = sel['register_number']?.toString() ?? 'N/A';
          final String department = sel['department']?.toString() ?? '';
          final String position = sel['position']?.toString() ?? 'Unspecified';
          final dynamic jerseyNumber = sel['jersey_number'];

          final String avatarText = jerseyNumber != null
              ? '#$jerseyNumber'
              : (playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P');

          final int? selectionId = sel['id'] is int
              ? sel['id'] as int
              : int.tryParse(sel['id']?.toString() ?? '');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 22,
                        child: Text(
                          avatarText,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerName,
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              department.isNotEmpty ? '$regNumber • $department' : regNumber,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Position: $position',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(status: 'PENDING'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: selectionId == null
                            ? null
                            : () {
                                final reasonController = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Reject Selection - $playerName'),
                                    content: TextField(
                                      controller: reasonController,
                                      decoration: const InputDecoration(
                                        labelText: 'Rejection Reason',
                                        hintText: 'e.g. Fitness concern or academic conflict',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          final success = await staffProvider.rejectSelection(selectionId, reasonController.text);
                                          if (context.mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Selection rejected for $playerName.'), backgroundColor: AppColors.error),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(staffProvider.error ?? 'Failed to reject selection.'), backgroundColor: AppColors.error),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(0, 36)),
                                        child: const Text('Reject'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                        label: const Text('Reject'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: selectionId == null
                            ? null
                            : () async {
                                final success = await staffProvider.approveSelection(selectionId);
                                if (context.mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$playerName approved for match! Notification sent.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(staffProvider.error ?? 'Failed to approve selection.'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
