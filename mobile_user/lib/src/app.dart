import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
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
    final token = await _sessionStore.token;
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
          ? const _SplashScreen()
          : _isLoggedIn
          ? HomeScreen(api: _api, onLogout: _handleLogout)
          : AuthScreen(api: _api, onLoggedIn: _handleLoggedIn),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
