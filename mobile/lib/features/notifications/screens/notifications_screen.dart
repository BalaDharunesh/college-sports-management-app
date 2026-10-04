import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../player/providers/player_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
      await playerProvider.fetchPlayerDashboardData();
      if (playerProvider.unreadNotificationsCount > 0) {
        await playerProvider.markAllNotificationsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final notifications = playerProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Center'),
        actions: [
          if (notifications.any((n) => n['is_read'] != 1 && n['is_read'] != true))
            TextButton.icon(
              onPressed: () => playerProvider.markAllNotificationsRead(),
              icon: const Icon(Icons.done_all, size: 18, color: Colors.white),
              label: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
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
                  color: isRead ? AppColors.surface : AppColors.secondary.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? AppColors.textSecondary.withValues(alpha: 0.2) : AppColors.secondary,
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
                        Text(
                          notif['message'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      _showNotificationDetail(context, notif);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showNotificationDetail(BuildContext context, Map<String, dynamic> notif) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 18,
              child: Icon(_getIconForType(notif['type']), color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notif['title'] ?? 'Notification Details',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif['message'] ?? '',
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Received: ${notif['created_at'] ?? 'N/A'}',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
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
