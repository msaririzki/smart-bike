import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';

class SmartBikeUserApp extends StatefulWidget {
  const SmartBikeUserApp({super.key});

  @override
  State<SmartBikeUserApp> createState() => _SmartBikeUserAppState();
}

class _SmartBikeUserAppState extends State<SmartBikeUserApp> {
  late final SessionStore _sessionStore;
  late final ApiClient _api;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _api = ApiClient(_sessionStore);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Mengeksekusi cek token & delay 2 detik secara paralel
    final results = await Future.wait([
      _sessionStore.token,
      Future.delayed(const Duration(seconds: 2)),
    ]);
    
    final token = results[0];
    setState(() {
      _isLoggedIn = token != null;
      _isLoading = false;
    });
  }

  Future<void> _handleLoggedIn() async {
    setState(() => _isLoggedIn = true);
  }

  Future<void> _handleLogout() async {
    try {
      await _api.logout();
    } finally {
      await _sessionStore.clear();
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0f766e),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _isLoading
          ? const SplashScreen()
          : _isLoggedIn
          ? HomeScreen(api: _api, onLogout: _handleLogout)
          : AuthScreen(api: _api, onLoggedIn: _handleLoggedIn),
    );
  }
}
