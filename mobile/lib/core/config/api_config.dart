import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Dynamically resolves host depending on environment/platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 points to host localhost in Android Emulator
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String sports = '/sports';
  static const String myTeam = '/teams/my-team';
  static String teamById(int id) => '/teams/$id';

  static const String players = '/players';
  static String playerById(int id) => '/players/$id';
  static String deactivatePlayer(int id) => '/players/$id/deactivate';

  static const String matches = '/matches';
  static String matchById(int id) => '/matches/$id';
  static String cancelMatch(int id) => '/matches/$id/cancel';
  static String matchSelections(int id) => '/matches/$id/selections';
  static String approveSelection(int id) => '/selections/$id/approve';
  static String rejectSelection(int id) => '/selections/$id/reject';
  static String matchResult(int id) => '/matches/$id/result';

  static const String odRequests = '/od-requests';
  static String approveOd(int id) => '/od-requests/$id/approve';
  static String rejectOd(int id) => '/od-requests/$id/reject';

  static const String tadaRequests = '/tada-requests';
  static String approveTada(int id) => '/tada-requests/$id/approve';
  static String rejectTada(int id) => '/tada-requests/$id/reject';

  static const String training = '/training';
  static String cancelTraining(int id) => '/training/$id/cancel';

  static const String feedback = '/feedback';
  static String respondFeedback(int id) => '/feedback/$id/respond';

  static const String notifications = '/notifications';
  static const String markNotificationsRead = '/notifications/read-all';
  static String markSingleNotificationRead(int id) => '/notifications/$id/read';
  static const String deviceToken = '/notifications/device-token';
}
