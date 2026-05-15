import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'package:mobile_user/src/theme/app_colors.dart';

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
    } on ApiException {
      // Token bisa sudah tidak valid, misalnya setelah reset password.
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
          seedColor: AppColors.primaryLight,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFEDF5F0),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFEDF5F0),
          foregroundColor: Color(0xff111827),
          titleTextStyle: TextStyle(
            color: Color(0xff111827),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xffdcfce7),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? AppColors.primaryLight
                  : const Color(0xff6b7280),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? AppColors.primaryLight
                  : const Color(0xff6b7280),
              size: 24,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xffd1d5db),
            disabledForegroundColor: const Color(0xff6b7280),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff111827),
            side: const BorderSide(color: Color(0xffe5e7eb)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
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
