import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/staff_provider.dart';

class StaffTadaApprovalsScreen extends StatelessWidget {
  const StaffTadaApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final tadaRequests = staffProvider.tadaRequests;

    return Scaffold(
      appBar: AppBar(title: const Text('TA/DA Claim Approvals')),
      body: tadaRequests.isEmpty
          ? const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No TA/DA Claims Found',
              message: 'Captain has not submitted any travel & daily allowance claims yet.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tadaRequests.length,
              itemBuilder: (context, index) {
                final req = tadaRequests[index];
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
                                req['match_title'] ?? 'Travel Allowance Claim',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(status: req['status']),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Claimant Captain: ${req['captain_name']}'),
                        Text(
                          'Estimated Amount: \$${req['estimated_amount']}',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        if (req['actual_amount'] != null)
                          Text('Approved Amount: \$${req['actual_amount']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Travel Details: ${req['travel_details']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 10),
                        Text('Covered Players (${players.length}):', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                        Wrap(
                          spacing: 6,
                          children: players.map((p) => Chip(
                            label: Text(p['player_name'], style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.background,
                          )).toList(),
                        ),
                        if (isPending) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  final success = await staffProvider.rejectTada(req['id'], 'Claim rejected by sports office');
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('TA/DA Claim Rejected'), backgroundColor: AppColors.error),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Reject Claim'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final success = await staffProvider.approveTada(req['id'], null, 'Sanctioned by sports coordinator');
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('TA/DA Claim Approved!'), backgroundColor: AppColors.success),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('Approve Claim'),
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
