import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
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

    int? selectedMatchId = matches.isNotEmpty ? matches.first['id'] : null;
    final travelCtrl = TextEditingController(text: 'Bus transport for 15 squad members + energy drinks & lunch allowances.');
    final amountCtrl = TextEditingController(text: '2450.00');
    final remarksCtrl = TextEditingController(text: 'Bills & receipts will be submitted post match.');
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
                Text('Submit Travel Allowance (TA/DA) Claim', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedMatchId,
                  decoration: const InputDecoration(labelText: 'Match'),
                  items: matches.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['title']))).toList(),
                  onChanged: (v) => setModalState(() => selectedMatchId = v),
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: travelCtrl, label: 'Travel & Allowance Breakdown', hint: 'Bus fare, meals, refreshments'),
                const SizedBox(height: 12),
                CustomTextField(controller: amountCtrl, label: 'Estimated Total Amount (\$)', keyboardType: TextInputType.number, hint: '2450.00'),
                const SizedBox(height: 12),
                CustomTextField(controller: remarksCtrl, label: 'Remarks', hint: 'Notes for sports accountant'),
                const SizedBox(height: 16),
                Text('Select Covered Players:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                Column(
                  children: players.map((p) => CheckboxListTile(
                    value: selectedPlayerIds.contains(p['player_id']),
                    title: Text(p['name']),
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
                  text: 'Submit TA/DA Claim for Staff Approval',
                  onPressed: () async {
                    if (selectedMatchId == null || amountCtrl.text.isEmpty || selectedPlayerIds.isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await captainProvider.submitTadaRequest({
                      'matchId': selectedMatchId,
                      'travelDetails': travelCtrl.text,
                      'estimatedAmount': double.parse(amountCtrl.text),
                      'remarks': remarksCtrl.text,
                      'playerIds': selectedPlayerIds.toList(),
                    });
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TA/DA Claim submitted to staff! Status: PENDING'), backgroundColor: AppColors.success),
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(req['match_title'] ?? "TA/DA Claim", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text('Estimated Amount: \$${req['estimated_amount']}\nTravel: ${req['travel_details']}'),
                    trailing: StatusBadge(status: req['status']),
                  ),
                );
              },
            ),
    );
  }
}
