import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';

class PlayerProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _team;
  List<dynamic> _matches = [];
  List<dynamic> _trainingSchedules = [];
  List<dynamic> _notifications = [];
  int _unreadNotificationsCount = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? get team => _team;
  List<dynamic> get matches => _matches;
  List<dynamic> get trainingSchedules => _trainingSchedules;
  List<dynamic> get notifications => _notifications;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  // Next upcoming match
  Map<String, dynamic>? get nextMatch {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final upcoming = _matches.where((m) {
      final status = m['status']?.toString().toUpperCase() ?? '';
      if (status == 'COMPLETED') return false;
      final dateStr = m['match_date']?.toString() ?? '';
      if (dateStr.isNotEmpty && dateStr.compareTo(todayStr) < 0) return false;
      return true;
    }).toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    return null;
  }

  // Next training session
  Map<String, dynamic>? get nextTraining {
    final active = _trainingSchedules.where((t) => t['is_cancelled'] == 0 || t['is_cancelled'] == false).toList();
    if (active.isNotEmpty) return active.first;
    return null;
  }

  Future<void> fetchPlayerDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiClient.get(ApiConfig.myTeam),
        _apiClient.get(ApiConfig.matches),
        _apiClient.get(ApiConfig.training),
        _apiClient.get(ApiConfig.notifications),
      ]);

      if (results[0].data['success'] == true) _team = results[0].data['team'];
      if (results[1].data['success'] == true) _matches = results[1].data['matches'] ?? [];
      if (results[2].data['success'] == true) _trainingSchedules = results[2].data['schedules'] ?? [];
      if (results[3].data['success'] == true) {
        _notifications = results[3].data['notifications'] ?? [];
        _unreadNotificationsCount = results[3].data['unreadCount'] ?? 0;
      }
    } catch (e) {
      _error = 'Failed to load player dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1 && (_notifications[index]['is_read'] == 0 || _notifications[index]['is_read'] == false)) {
        _notifications[index]['is_read'] = 1;
        if (_unreadNotificationsCount > 0) {
          _unreadNotificationsCount--;
        }
        notifyListeners();
      }
      await _apiClient.patch(ApiConfig.markSingleNotificationRead(notificationId));
      await fetchPlayerDashboardData();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      _unreadNotificationsCount = 0;
      for (var n in _notifications) {
        n['is_read'] = 1;
      }
      notifyListeners();
      await _apiClient.patch(ApiConfig.markNotificationsRead);
      await fetchPlayerDashboardData();
    } catch (e) {
      // Ignore
    }
  }
}
