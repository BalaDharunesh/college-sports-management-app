import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import 'dart:convert';
import '../../../core/utils/file_downloader.dart';
import '../../../core/utils/date_picker_helper.dart';
import '../providers/captain_provider.dart';

class CaptainTadaRequestScreen extends StatefulWidget {
  const CaptainTadaRequestScreen({super.key});

  @override
  State<CaptainTadaRequestScreen> createState() => _CaptainTadaRequestScreenState();
}

class _CaptainTadaRequestScreenState extends State<CaptainTadaRequestScreen> {
  void _openCreateTadaModal(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context, listen: false);
    final matches = captainProvider.matches;
    final players = captainProvider.players;

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches scheduled yet to submit a TA/DA claim.'), backgroundColor: AppColors.error),
      );
      return;
    }

    int? selectedMatchId = matches.first['id'];
    final initialMatch = matches.first;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final matchDateStr = initialMatch['match_date'] ?? todayStr;

    final dateCtrl = TextEditingController(text: matchDateStr);

    final Set<int> selectedPlayerIds = players.map<int>((p) => p['player_id'] as int).toSet();
    String? playerError;
    String? selectedFileName;
    String? selectedFileSize;
    List<int>? uploadedBytes;
    String? fileError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedMatch = matches.firstWhere(
            (m) => m['id'] == selectedMatchId,
            orElse: () => matches.first,
          );

          final allSelected = selectedPlayerIds.length == players.length && players.isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Submit Travel Allowance (TA/DA) Claim', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 1. Match Name
                  DropdownButtonFormField<int>(
                    initialValue: selectedMatchId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '1. Match Name *',
                      prefixIcon: Icon(Icons.sports_cricket_outlined),
                    ),
                    items: matches.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(
                      value: m['id'],
                      child: Text(m['title'] ?? 'Match', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        final m = matches.firstWhere((item) => item['id'] == v, orElse: () => matches.first);
                        setModalState(() {
                          selectedMatchId = v;
                          if (m['match_date'] != null && m['match_date'].toString().isNotEmpty) {
                            dateCtrl.text = m['match_date'];
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. Match Date
                  CustomTextField(
                    controller: dateCtrl,
                    label: '2. Match Date *',
                    hint: 'YYYY-MM-DD',
                    prefixIcon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: () => selectDate(context, dateCtrl),
                    validator: validateFutureDate,
                  ),
                  const SizedBox(height: 14),

                  // 3. Select Players for TA/DA Approval
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '3. Select Players for TA/DA Approval *',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (allSelected) {
                              selectedPlayerIds.clear();
                            } else {
                              selectedPlayerIds.addAll(players.map<int>((p) => p['player_id'] as int));
                            }
                            playerError = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: playerError != null ? AppColors.error : AppColors.border,
                        width: playerError != null ? 1.5 : 1,
                      ),
                    ),
                    child: players.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No registered team players found.',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: players.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final p = players[idx];
                              final pId = p['player_id'] as int;
                              final isSelected = selectedPlayerIds.contains(pId);
                              final pName = p['name'] ?? 'Player #${p['jersey_number'] ?? pId}';
                              final regNum = p['register_number'] ?? '';

                              return CheckboxListTile(
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                activeColor: AppColors.primary,
                                title: Text(
                                  pName,
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                subtitle: regNum.isNotEmpty
                                    ? Text(regNum, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary))
                                    : null,
                                value: isSelected,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedPlayerIds.add(pId);
                                    } else {
                                      selectedPlayerIds.remove(pId);
                                    }
                                    playerError = null;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  if (playerError != null) ...[
                    const SizedBox(height: 4),
                    Text(playerError!, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.error)),
                  ],
                  const SizedBox(height: 14),

                  // 4. Upload Form
                  Text(
                    '4. Upload TA/DA Form / Document *',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedFileName == null)
                    InkWell(
                      onTap: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.bytes != null && file.bytes!.isNotEmpty) {
                              uploadedBytes = file.bytes;
                              registerUploadedFile(file.name, file.bytes!);
                            }
                            final sizeInKb = (file.size / 1024).toStringAsFixed(1);
                            setModalState(() {
                              selectedFileName = file.name;
                              selectedFileSize = '$sizeInKb KB';
                              fileError = null;
                            });
                          }
                        } catch (e) {
                          setModalState(() {
                            fileError = 'Failed to pick file.';
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: fileError != null ? AppColors.error : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.primary),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Click to upload signed TA/DA Form / Bills',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports PDF, JPG, PNG, DOC (Max 10MB)',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              selectedFileName!.endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                              color: AppColors.success,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFileName!,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  selectedFileSize ?? '',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () {
                              setModalState(() {
                                selectedFileName = null;
                                selectedFileSize = null;
                                uploadedBytes = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  if (fileError != null) ...[
                    const SizedBox(height: 6),
                    Text(fileError!, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.error)),
                  ],
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: 'Submit TA/DA Claim for Staff Approval',
                    onPressed: () async {
                      if (selectedMatchId == null) return;

                      if (selectedPlayerIds.isEmpty && players.isNotEmpty) {
                        setModalState(() {
                          playerError = 'Please select at least one player for TA/DA approval.';
                        });
                        return;
                      }

                      if (selectedFileName == null) {
                        setModalState(() {
                          fileError = 'Please upload the TA/DA Form or Bills document.';
                        });
                        return;
                      }

                      final dateErr = validateFutureDate(dateCtrl.text.trim());
                      if (dateErr != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(dateErr), backgroundColor: AppColors.error),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final matchTitle = selectedMatch['title'] ?? 'Match';

                      String fileDataTag = '';
                      if (uploadedBytes != null && uploadedBytes!.length < 3 * 1024 * 1024) {
                        final b64 = base64Encode(uploadedBytes!);
                        fileDataTag = ' [FILEDATA:$b64]';
                      }

                      final success = await captainProvider.submitTadaRequest({
                        'matchId': selectedMatchId,
                        'travelDetails': '$matchTitle TA/DA Claim',
                        'estimatedAmount': 0.0,
                        'remarks': '📄 Attached TA/DA Form: $selectedFileName ($selectedFileSize). Match Date: ${dateCtrl.text.trim()}.$fileDataTag',
                        'playerIds': selectedPlayerIds.toList(),
                      });

                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('TA/DA Claim & Form submitted to staff! Status: PENDING'), backgroundColor: AppColors.success),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(captainProvider.error ?? 'Failed to submit TA/DA Claim.'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context);
    final tadaRequests = captainProvider.tadaRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team TA/DA Claims'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openCreateTadaModal(context),
          ),
        ],
      ),
      body: tadaRequests.isEmpty
          ? const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No TA/DA Claims Submitted',
              message: 'Click + to submit a Travel & Daily Allowance claim for your match travel.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tadaRequests.length,
              itemBuilder: (context, index) {
                final req = tadaRequests[index];
                final remarksRaw = req['remarks']?.toString() ?? '';
                final cleanRemarks = remarksRaw.contains(' [FILEDATA:')
                    ? remarksRaw.substring(0, remarksRaw.indexOf(' [FILEDATA:')).trim()
                    : remarksRaw.trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(req['match_title'] ?? "TA/DA Claim", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text('Travel: ${req['travel_details']}\n$cleanRemarks'),
                    trailing: StatusBadge(status: req['status']),
                  ),
                );
              },
            ),
    );
  }
}
