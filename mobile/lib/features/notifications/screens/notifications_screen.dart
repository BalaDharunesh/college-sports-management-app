import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../player/providers/player_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final notifications = playerProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Center'),
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No Notifications',
              message: 'You have no recent notifications or official match updates.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['is_read'] == 1 || notif['is_read'] == true;

                return Card(
                  color: isRead ? AppColors.surface : AppColors.secondary.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? AppColors.textSecondary.withOpacity(0.2) : AppColors.secondary,
                      child: Icon(
                        _getIconForType(notif['type']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notif['title'],
                      style: GoogleFonts.outfit(
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['message']),
                        const SizedBox(height: 4),
                        Text(
                          notif['created_at'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        playerProvider.markNotificationRead(notif['id']);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'MATCH_SELECTION':
        return Icons.emoji_events_outlined;
      case 'MATCH_RESULT':
        return Icons.scoreboard_outlined;
      case 'TRAINING_SCHEDULE':
        return Icons.fitness_center_outlined;
      case 'OD_DECISION':
      case 'TADA_DECISION':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
