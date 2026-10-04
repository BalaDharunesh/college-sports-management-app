import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

void showViewSquadModal(BuildContext context, Map<String, dynamic> match) {
  List selections = (match['selections'] as List?) ?? [];
  bool isLoading = true;
  bool fetched = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        if (!fetched && match['id'] != null) {
          fetched = true;
          ApiClient().get(ApiConfig.matchSelections(match['id'])).then((res) {
            if (res.data != null && res.data['success'] == true) {
              if (context.mounted) {
                setState(() {
                  selections = res.data['selections'] ?? [];
                  isLoading = false;
                });
              }
            } else {
              if (context.mounted) {
                setState(() => isLoading = false);
              }
            }
          }).catchError((_) {
            if (context.mounted) {
              setState(() => isLoading = false);
            }
          });
        }

        final approvedSquad = selections.where((s) => s['status'] == 'APPROVED').toList();
        final pendingSquad = selections.where((s) => s['status'] == 'PENDING').toList();
        final displaySquad = approvedSquad.isNotEmpty
            ? approvedSquad
            : selections.where((s) => s['status'] != 'REJECTED').toList();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Match Squad List',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            match['title'] ?? 'Match',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Date: ${match['match_date'] ?? 'N/A'}',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          match['venue'] ?? 'Venue N/A',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Official Fixed Squad (${displaySquad.length} Players)',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (approvedSquad.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Staff Approved',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                      )
                    else if (pendingSquad.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Pending Approval',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isLoading && displaySquad.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (displaySquad.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No squad players fixed for this match yet.',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displaySquad.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = displaySquad[index];
                      final name = p['player_name'] ?? 'Player';
                      final regNo = p['register_number'] ?? '';
                      final pos = p['position'] ?? 'Squad Member';
                      final jNo = p['jersey_number'];
                      final status = p['status'] ?? 'APPROVED';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            jNo != null ? '#$jNo' : '${index + 1}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                        title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '$pos${regNo.isNotEmpty ? " • $regNo" : ""}',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: StatusBadge(status: status),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    ),
  );
}
