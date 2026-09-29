import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';

class StaffOdApprovalsScreen extends StatelessWidget {
  const StaffOdApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final odRequests = staffProvider.odRequests;

    return Scaffold(
      appBar: AppBar(title: const Text('On-Duty (OD) Requests')),
      body: odRequests.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No OD Requests Found',
              message: 'Captain has not submitted any On-Duty requests yet.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: odRequests.length,
              itemBuilder: (context, index) {
                final req = odRequests[index];
                final isPending = req['status'] == 'PENDING';
                final players = req['players'] as List? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
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
                                req['match_title'] ?? 'Match OD',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(status: req['status']),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Submitted by Captain: ${req['captain_name']}'),
                        Text('OD Date: ${req['request_date']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Reason: ${req['reason']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        if (req['remarks'] != null) Text('Remarks: ${req['remarks']}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        Text('Covered Players (${players.length}):', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: players.map((p) => Chip(
                            label: Text('${p['player_name']} (${p['register_number']})', style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.background,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                        if (isPending) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  final success = await staffProvider.rejectOd(req['id'], 'Criteria not fulfilled');
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('OD Request Rejected'), backgroundColor: AppColors.error),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Reject OD'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final success = await staffProvider.approveOd(req['id'], 'Approved by sports staff');
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('OD Request Approved!'), backgroundColor: AppColors.success),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('Approve OD'),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
