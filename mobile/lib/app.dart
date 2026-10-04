import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/staff/providers/staff_provider.dart';
import 'features/captain/providers/captain_provider.dart';
import 'features/player/providers/player_provider.dart';

class SportSyncApp extends StatefulWidget {
  const SportSyncApp({super.key});

  @override
  State<SportSyncApp> createState() => _SportSyncAppState();
}

class _SportSyncAppState extends State<SportSyncApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => CaptainProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp.router(
        title: 'SportSync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
