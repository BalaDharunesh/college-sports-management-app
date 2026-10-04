import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/file_downloader.dart';
import '../providers/staff_provider.dart';

class StaffTadaApprovalsScreen extends StatelessWidget {
  const StaffTadaApprovalsScreen({super.key});

  void _downloadForm(BuildContext context, String fileName) {
    triggerLocalFileDownload(fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('TA/DA Form "$fileName" downloaded to your local PC Downloads folder!'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showFormViewer(BuildContext context, Map<String, dynamic> req, String fileName, String matchDate) {
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
                      'Official TA/DA Claim Form',
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
                          child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 28),
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
                                'TRAVEL ALLOWANCE (TA/DA) CLAIM',
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
                    _buildDocRow('Claimant Captain:', 'Captain ${req['captain_name'] ?? "N/A"}'),
                    const SizedBox(height: 6),
                    _buildDocRow('Match Date:', matchDate.isNotEmpty ? matchDate : 'N/A'),
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
                text: 'Download TA/DA Form ($fileName)',
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
          width: 120,
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
                final remarksStr = req['remarks']?.toString() ?? '';

                // Extract filename & match date from entered payload
                String fileName = 'TADA_Form.pdf';
                if (remarksStr.contains('Attached TA/DA Form:')) {
                  final parts = remarksStr.split('Attached TA/DA Form:');
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

                if (remarksStr.contains('[FILEDATA:')) {
                  try {
                    final b64Start = remarksStr.indexOf('[FILEDATA:') + 10;
                    final b64End = remarksStr.indexOf(']', b64Start);
                    if (b64End > b64Start) {
                      final b64Str = remarksStr.substring(b64Start, b64End);
                      final decodedBytes = base64Decode(b64Str);
                      registerUploadedFile(fileName, decodedBytes);
                    }
                  } catch (_) {}
                }

                String matchDate = '';
                if (remarksStr.contains('Match Date:')) {
                  final parts = remarksStr.split('Match Date:');
                  if (parts.length > 1) {
                    matchDate = parts[1].split('.')[0].trim();
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
                                req['match_title'] ?? 'Travel Allowance Claim',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            StatusBadge(status: req['status']),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Submitted by Captain: ${req['captain_name']}'),
                        if (matchDate.isNotEmpty) Text('Match Date: $matchDate', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (req['players'] != null && (req['players'] as List).isNotEmpty)
                          Text(
                            'Players (${(req['players'] as List).length}): ${(req['players'] as List).map((p) => p['player_name'] ?? 'Player').join(', ')}',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),

                        // Interactive Attached TA/DA Form Card for Current Request
                        InkWell(
                          onTap: () => _showFormViewer(context, req, fileName, matchDate),
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
                                        'Attached TA/DA Form: $fileName',
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
                                  final success = await staffProvider.rejectTada(req['id'], 'Claim rejected by sports office');
                                  if (context.mounted && success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('TA/DA Claim Rejected'), backgroundColor: AppColors.error),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size(0, 36)),
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
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 36)),
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
