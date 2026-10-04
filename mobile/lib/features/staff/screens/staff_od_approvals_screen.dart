import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/file_downloader.dart';
import '../providers/staff_provider.dart';

class StaffOdApprovalsScreen extends StatelessWidget {
  const StaffOdApprovalsScreen({super.key});

  void _downloadForm(BuildContext context, String fileName) {
    triggerLocalFileDownload(fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('OD Form "$fileName" downloaded to your local PC Downloads folder!'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showFormViewer(BuildContext context, Map<String, dynamic> req, String fileName, String dateRange, String venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
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
                    child: Text(
                      'Official On-Duty (OD) Form',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Form Document Box Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEPARTMENT OF PHYSICAL EDUCATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'STUDENT ON-DUTY (OD) APPLICATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: req['status']),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // Document Details Grid (Only Entered Information)
                    _buildDocRow('Match Name:', req['match_title'] ?? 'N/A'),
                    const SizedBox(height: 6),
                    _buildDocRow('Submitted By:', 'Captain ${req['captain_name'] ?? "N/A"}'),
                    const SizedBox(height: 6),
                    _buildDocRow('Match Dates:', dateRange.isNotEmpty ? dateRange : (req['request_date'] ?? 'N/A')),
                    const SizedBox(height: 6),
                    _buildDocRow('Match Venue:', venue.isNotEmpty ? venue : 'N/A'),
                    const SizedBox(height: 6),
                    _buildDocRow(
                      'Covered Players:',
                      (req['players'] != null && (req['players'] as List).isNotEmpty)
                          ? (req['players'] as List).map((p) => p['player_name'] ?? 'Player').join(', ')
                          : 'All Team Members',
                    ),
                    const SizedBox(height: 6),
                    _buildDocRow('Attached Form:', fileName),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Download Button
              CustomButton(
                text: 'Download OD Form ($fileName)',
                icon: Icons.file_download_outlined,
                onPressed: () {
                  Navigator.pop(ctx);
                  _downloadForm(context, fileName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

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
                final remarksStr = req['remarks']?.toString() ?? '';

                // Extract filename, venue, and date range from entered payload
                String fileName = 'OD_Form.pdf';
                if (remarksStr.contains('Attached OD Form:')) {
                  final parts = remarksStr.split('Attached OD Form:');
                  if (parts.length > 1) {
                    final temp = parts[1].trim();
                    final spaceIdx = temp.indexOf(' ');
                    if (spaceIdx > 0) {
                      fileName = temp.substring(0, spaceIdx).trim();
                    } else {
                      fileName = temp;
                    }
                  }
                }

                String venue = '';
                if (remarksStr.contains('Venue:')) {
                  final parts = remarksStr.split('Venue:');
                  if (parts.length > 1) {
                    venue = parts[1].split('.')[0].trim();
                  }
                }

                String dates = req['request_date'] ?? '';
                if (remarksStr.contains('Dates:')) {
                  final parts = remarksStr.split('Dates:');
                  if (parts.length > 1) {
                    dates = parts[1].split('.')[0].trim();
                  }
                }

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
                        Text('Match Dates: $dates', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (venue.isNotEmpty) Text('Venue: $venue', style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (req['players'] != null && (req['players'] as List).isNotEmpty)
                          Text(
                            'Players (${(req['players'] as List).length}): ${(req['players'] as List).map((p) => p['player_name'] ?? 'Player').join(', ')}',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),

                        // Interactive Attached OD Form Card for Current Request
                        InkWell(
                          onTap: () => _showFormViewer(context, req, fileName, dates, venue),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attached OD Form: $fileName',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap to view form & download',
                                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _downloadForm(context, fileName),
                                  icon: const Icon(Icons.file_download_outlined, size: 16),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size(0, 36)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 36)),
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
