import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/player_provider.dart';

class PlayerScheduleScreen extends StatelessWidget {
  const PlayerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final training = playerProvider.trainingSchedules;

    return Scaffold(
      appBar: AppBar(title: const Text('My Training & Practice Schedule')),
      body: training.isEmpty
          ? const EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'No Net Practice Sessions',
              message: 'Staff has not scheduled any practice sessions yet.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: training.length,
              itemBuilder: (context, index) {
                final ts = training[index];
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
                    ),
                  ),
                );
              },
            ),
    );
  }
}
