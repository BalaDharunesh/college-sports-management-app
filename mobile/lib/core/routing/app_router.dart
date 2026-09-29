import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';

// Staff Screens
import '../../features/staff/screens/staff_dashboard_screen.dart';
import '../../features/staff/screens/staff_players_screen.dart';
import '../../features/staff/screens/staff_create_player_screen.dart';
import '../../features/staff/screens/staff_matches_screen.dart';
import '../../features/staff/screens/staff_create_match_screen.dart';
import '../../features/staff/screens/staff_selection_approval_screen.dart';
import '../../features/staff/screens/staff_od_approvals_screen.dart';
import '../../features/staff/screens/staff_tada_approvals_screen.dart';
import '../../features/staff/screens/staff_training_screen.dart';
import '../../features/staff/screens/staff_feedback_screen.dart';

// Captain Screens
import '../../features/captain/screens/captain_dashboard_screen.dart';
import '../../features/captain/screens/captain_squad_selection_screen.dart';
import '../../features/captain/screens/captain_od_request_screen.dart';
import '../../features/captain/screens/captain_tada_request_screen.dart';
import '../../features/captain/screens/captain_feedback_screen.dart';

// Player Screens
import '../../features/player/screens/player_dashboard_screen.dart';
import '../../features/player/screens/player_profile_screen.dart';
import '../../features/player/screens/player_matches_screen.dart';
import '../../features/player/screens/player_schedule_screen.dart';

// Shared
import '../../features/notifications/screens/notifications_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final status = authProvider.status;
      final user = authProvider.user;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/forgot-password';

      if (status == AuthStatus.loading || status == AuthStatus.uninitialized) {
        return '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // If authenticated and trying to access splash or login, redirect to role dashboard
      if (isLoggingIn || state.matchedLocation == '/splash') {
        if (user?.role == 'STAFF') return '/staff/dashboard';
        if (user?.role == 'CAPTAIN') return '/captain/dashboard';
        return '/player/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

      // Staff Routes
      GoRoute(path: '/staff/dashboard', builder: (context, state) => const StaffDashboardScreen()),
      GoRoute(path: '/staff/players', builder: (context, state) => const StaffPlayersScreen()),
      GoRoute(path: '/staff/create-player', builder: (context, state) => const StaffCreatePlayerScreen()),
      GoRoute(path: '/staff/matches', builder: (context, state) => const StaffMatchesScreen()),
      GoRoute(path: '/staff/create-match', builder: (context, state) => const StaffCreateMatchScreen()),
      GoRoute(path: '/staff/selections', builder: (context, state) => const StaffSelectionApprovalScreen()),
      GoRoute(path: '/staff/od-approvals', builder: (context, state) => const StaffOdApprovalsScreen()),
      GoRoute(path: '/staff/tada-approvals', builder: (context, state) => const StaffTadaApprovalsScreen()),
      GoRoute(path: '/staff/training', builder: (context, state) => const StaffTrainingScreen()),
      GoRoute(path: '/staff/feedback', builder: (context, state) => const StaffFeedbackScreen()),

      // Captain Routes
      GoRoute(path: '/captain/dashboard', builder: (context, state) => const CaptainDashboardScreen()),
      GoRoute(path: '/captain/team', builder: (context, state) => const StaffPlayersScreen()),
      GoRoute(path: '/captain/squad-selection', builder: (context, state) => const CaptainSquadSelectionScreen()),
      GoRoute(path: '/captain/od-request', builder: (context, state) => const CaptainOdRequestScreen()),
      GoRoute(path: '/captain/tada-request', builder: (context, state) => const CaptainTadaRequestScreen()),
      GoRoute(path: '/captain/feedback', builder: (context, state) => const CaptainFeedbackScreen()),

      // Player Routes
      GoRoute(path: '/player/dashboard', builder: (context, state) => const PlayerDashboardScreen()),
      GoRoute(path: '/player/profile', builder: (context, state) => const PlayerProfileScreen()),
      GoRoute(path: '/player/matches', builder: (context, state) => const PlayerMatchesScreen()),
      GoRoute(path: '/player/schedule', builder: (context, state) => const PlayerScheduleScreen()),

      // Notifications
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    ],
  );
}
