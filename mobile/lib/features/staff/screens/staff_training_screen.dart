import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/staff_provider.dart';

class StaffTrainingScreen extends StatefulWidget {
  const StaffTrainingScreen({super.key});

  @override
  State<StaffTrainingScreen> createState() => _StaffTrainingScreenState();
}

class _StaffTrainingScreenState extends State<StaffTrainingScreen> {
  void _openAddTrainingModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T')[0]);
    final startCtrl = TextEditingController(text: '06:30:00');
    final endCtrl = TextEditingController(text: '08:30:00');
    final venueCtrl = TextEditingController(text: 'University Sports Nets');
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Schedule Training Session', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(controller: titleCtrl, label: 'Training Session Title', hint: 'e.g. Batting & Bowling Practice'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: dateCtrl, label: 'Date', hint: 'YYYY-MM-DD')),
                const SizedBox(width: 8),
                Expanded(child: CustomTextField(controller: startCtrl, label: 'Start Time', hint: '06:30:00')),
                const SizedBox(width: 8),
                Expanded(child: CustomTextField(controller: endCtrl, label: 'End Time', hint: '08:30:00')),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(controller: venueCtrl, label: 'Venue Location', hint: 'Net 2 & Pitch 3'),
            const SizedBox(height: 12),
            CustomTextField(controller: descCtrl, label: 'Training Instructions', hint: 'Drills and focus areas'),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Announce Training Schedule',
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final staffProvider = Provider.of<StaffProvider>(context, listen: false);
                final success = await staffProvider.createTraining({
                  'title': titleCtrl.text,
                  'trainingDate': dateCtrl.text,
                  'startTime': startCtrl.text,
                  'endTime': endCtrl.text,
                  'venue': venueCtrl.text,
                  'description': descCtrl.text,
                });
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Training session announced! Team notified.'), backgroundColor: AppColors.success),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final schedules = staffProvider.trainingSchedules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openAddTrainingModal(context),
          ),
        ],
      ),
      body: schedules.isEmpty
          ? const EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'No Training Sessions',
              message: 'Click + to schedule net practice and fitness training sessions.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final ts = schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
                    ),
                    title: Text(ts['title'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Date: ${ts['training_date']} (${ts['start_time']} - ${ts['end_time']})\nVenue: ${ts['venue']}\n${ts['description'] ?? ""}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
