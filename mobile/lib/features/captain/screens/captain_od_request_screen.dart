import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/captain_provider.dart';

class CaptainOdRequestScreen extends StatefulWidget {
  const CaptainOdRequestScreen({super.key});

  @override
  State<CaptainOdRequestScreen> createState() => _CaptainOdRequestScreenState();
}

class _CaptainOdRequestScreenState extends State<CaptainOdRequestScreen> {
  void _openCreateOdModal(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context, listen: false);
    final matches = captainProvider.matches;
    final players = captainProvider.players;

    int? selectedMatchId = matches.isNotEmpty ? matches.first['id'] : null;
    final reasonCtrl = TextEditingController(text: 'Participation in Inter-College Tournament knockout match.');
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0]);
    final remarksCtrl = TextEditingController(text: 'Covers all selected squad players for full day academic credit.');
    final Set<int> selectedPlayerIds = players.map<int>((p) => p['player_id'] as int).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Submit On-Duty (OD) Claim', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedMatchId,
                  decoration: const InputDecoration(labelText: 'Match'),
                  items: matches.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['title']))).toList(),
                  onChanged: (v) => setModalState(() => selectedMatchId = v),
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: reasonCtrl, label: 'Exemption Reason', hint: 'e.g. Lab session exemption'),
                const SizedBox(height: 12),
                CustomTextField(controller: dateCtrl, label: 'Date of OD', hint: 'YYYY-MM-DD'),
                const SizedBox(height: 12),
                CustomTextField(controller: remarksCtrl, label: 'Additional Remarks', hint: 'Special notes'),
                const SizedBox(height: 16),
                Text('Select Players to Cover:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                Column(
                  children: players.map((p) => CheckboxListTile(
                    value: selectedPlayerIds.contains(p['player_id']),
                    title: Text(p['name'], style: const TextStyle(fontSize: 14)),
                    subtitle: Text(p['register_number'] ?? "", style: const TextStyle(fontSize: 12)),
                    onChanged: (chk) {
                      setModalState(() {
                        if (chk == true) selectedPlayerIds.add(p['player_id']);
                        else selectedPlayerIds.remove(p['player_id']);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Submit OD Claim for Staff Approval',
                  onPressed: () async {
                    if (selectedMatchId == null || selectedPlayerIds.isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await captainProvider.submitOdRequest({
                      'matchId': selectedMatchId,
                      'reason': reasonCtrl.text,
                      'requestDate': dateCtrl.text,
                      'remarks': remarksCtrl.text,
                      'playerIds': selectedPlayerIds.toList(),
                    });
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OD Request submitted to staff! Status: PENDING'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captainProvider = Provider.of<CaptainProvider>(context);
    final odRequests = captainProvider.odRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team OD Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openCreateOdModal(context),
          ),
        ],
      ),
      body: odRequests.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No OD Requests Submitted',
              message: 'Click + to submit an On-Duty claim for your squad players.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: odRequests.length,
              itemBuilder: (context, index) {
                final req = odRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(req['match_title'] ?? "OD Claim", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text('Date: ${req['request_date']}\nReason: ${req['reason']}'),
                    trailing: StatusBadge(status: req['status']),
                  ),
                );
              },
            ),
    );
  }
}
