import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';

class StaffProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _team;
  List<dynamic> _players = [];
  List<dynamic> _matches = [];
  List<dynamic> _odRequests = [];
  List<dynamic> _tadaRequests = [];
  List<dynamic> _trainingSchedules = [];
  List<dynamic> _feedbackList = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? get team => _team;
  List<dynamic> get players => _players;
  List<dynamic> get matches => _matches;
  List<dynamic> get odRequests => _odRequests;
  List<dynamic> get tadaRequests => _tadaRequests;
  List<dynamic> get trainingSchedules => _trainingSchedules;
  List<dynamic> get feedbackList => _feedbackList;

  // Dashboard Stats Computed Properties
  int get totalActivePlayers => _players.where((p) => p is Map && (p['player_active'] == 1 || p['is_active'] == 1)).length;

  int get pendingSelectionsCount {
    int count = 0;
    for (var m in _matches) {
      if (m is Map && m['selections'] is List) {
        for (var s in m['selections']) {
          if (s is Map && s['status']?.toString() == 'PENDING') count++;
        }
      }
    }
    return count;
  }

  int get pendingOdCount => _odRequests.where((r) => r['status'] == 'PENDING').length;
  int get pendingTadaCount => _tadaRequests.where((r) => r['status'] == 'PENDING').length;

  Future<void> fetchStaffDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiClient.get(ApiConfig.myTeam),
        _apiClient.get(ApiConfig.players),
        _apiClient.get(ApiConfig.matches),
        _apiClient.get(ApiConfig.odRequests),
        _apiClient.get(ApiConfig.tadaRequests),
        _apiClient.get(ApiConfig.training),
        _apiClient.get(ApiConfig.feedback),
      ]);

      if (results[0].data['success'] == true) _team = results[0].data['team'];
      if (results[1].data['success'] == true) _players = results[1].data['players'] ?? [];
      if (results[2].data['success'] == true) _matches = results[2].data['matches'] ?? [];
      if (results[3].data['success'] == true) _odRequests = results[3].data['odRequests'] ?? [];
      if (results[4].data['success'] == true) _tadaRequests = results[4].data['tadaRequests'] ?? [];
      if (results[5].data['success'] == true) _trainingSchedules = results[5].data['schedules'] ?? [];
      if (results[6].data['success'] == true) _feedbackList = results[6].data['feedbackList'] ?? [];
    } catch (e) {
      _error = 'Failed to load staff dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Player Management
  Future<bool> createPlayer(Map<String, dynamic> playerData) async {
    try {
      final res = await _apiClient.post(ApiConfig.players, data: playerData);
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> togglePlayerDeactivation(int playerId) async {
    try {
      final res = await _apiClient.patch(ApiConfig.deactivatePlayer(playerId));
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Match Management
  Future<bool> createMatch(Map<String, dynamic> matchData) async {
    try {
      final res = await _apiClient.post(ApiConfig.matches, data: matchData);
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Selection Approvals
  Future<bool> approveSelection(int selectionId) async {
    try {
      final res = await _apiClient.patch(ApiConfig.approveSelection(selectionId));
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      _error = res.data['message'] ?? 'Failed to approve selection.';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection or server error while approving selection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectSelection(int selectionId, String reason) async {
    try {
      final res = await _apiClient.patch(ApiConfig.rejectSelection(selectionId), data: {'reason': reason});
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      _error = res.data['message'] ?? 'Failed to reject selection.';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection or server error while rejecting selection.';
      notifyListeners();
      return false;
    }
  }

  // OD Approval
  Future<bool> approveOd(int odId, String? remarks) async {
    try {
      final res = await _apiClient.patch(ApiConfig.approveOd(odId), data: {'staffRemarks': remarks});
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectOd(int odId, String? remarks) async {
    try {
      final res = await _apiClient.patch(ApiConfig.rejectOd(odId), data: {'staffRemarks': remarks});
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // TA/DA Approval
  Future<bool> approveTada(int tadaId, double? actualAmount, String? remarks) async {
    try {
      final res = await _apiClient.patch(ApiConfig.approveTada(tadaId), data: {
        'actualAmount': actualAmount,
        'staffRemarks': remarks
      });
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTada(int tadaId, String? remarks) async {
    try {
      final res = await _apiClient.patch(ApiConfig.rejectTada(tadaId), data: {'staffRemarks': remarks});
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Training Schedule
  Future<bool> createTraining(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.training, data: data);
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Match Result
  Future<bool> submitResult(int matchId, dynamic teamScore, dynamic opponentScore, String outcome, String? remarks) async {
    try {
      final res = await _apiClient.post(ApiConfig.matchResult(matchId), data: {
        'teamScore': teamScore,
        'opponentScore': opponentScore,
        'outcome': outcome,
        'remarks': remarks
      });
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Feedback Response
  Future<bool> respondFeedback(int feedbackId, String response) async {
    try {
      final res = await _apiClient.post(ApiConfig.respondFeedback(feedbackId), data: {'response': response});
      if (res.data['success'] == true) {
        await fetchStaffDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
