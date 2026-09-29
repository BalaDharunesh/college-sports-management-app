import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api_config.dart';

class CaptainProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _team;
  List<dynamic> _players = [];
  List<dynamic> _matches = [];
  List<dynamic> _odRequests = [];
  List<dynamic> _tadaRequests = [];
  List<dynamic> _feedbackList = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? get team => _team;
  List<dynamic> get players => _players;
  List<dynamic> get matches => _matches;
  List<dynamic> get odRequests => _odRequests;
  List<dynamic> get tadaRequests => _tadaRequests;
  List<dynamic> get feedbackList => _feedbackList;

  Future<void> fetchCaptainDashboardData() async {
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
        _apiClient.get(ApiConfig.feedback),
      ]);

      if (results[0].data['success'] == true) _team = results[0].data['team'];
      if (results[1].data['success'] == true) _players = results[1].data['players'] ?? [];
      if (results[2].data['success'] == true) _matches = results[2].data['matches'] ?? [];
      if (results[3].data['success'] == true) _odRequests = results[3].data['odRequests'] ?? [];
      if (results[4].data['success'] == true) _tadaRequests = results[4].data['tadaRequests'] ?? [];
      if (results[5].data['success'] == true) _feedbackList = results[5].data['feedbackList'] ?? [];
    } catch (e) {
      _error = 'Failed to load captain dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit Squad Selection for a Match
  Future<bool> submitSquadSelection(int matchId, List<int> playerIds) async {
    try {
      final res = await _apiClient.post(
        ApiConfig.matchSelections(matchId),
        data: {'playerIds': playerIds},
      );
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      _error = res.data['message'] ?? 'Failed to submit selection.';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection or server error while submitting squad selection.';
      notifyListeners();
      return false;
    }
  }

  // Create Player
  Future<bool> createPlayer(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.players, data: data);
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Create Match for assigned team
  Future<bool> createMatch(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.matches, data: data);
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Submit OD Request
  Future<bool> submitOdRequest(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.odRequests, data: data);
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Submit TA/DA Request
  Future<bool> submitTadaRequest(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.tadaRequests, data: data);
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Submit Feedback
  Future<bool> submitFeedback(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post(ApiConfig.feedback, data: data);
      if (res.data['success'] == true) {
        await fetchCaptainDashboardData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
