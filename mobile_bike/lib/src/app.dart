import 'package:flutter/material.dart';

import 'features/auth/login_screen.dart';
import 'features/simulator/simulator_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _session = SessionStore();
  late final ApiClient _api;

  bool _loggedIn = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(_session);
    _checkSession();
  }

  Future<void> _checkSession() async {
    final logged = await _session.isLoggedIn;
    if (mounted) {
      setState(() {
        _loggedIn = logged;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    if (!_loggedIn) {
      return LoginScreen(
        api: _api,
        onLoggedIn: () => setState(() => _loggedIn = true),
      );
    }

    return SimulatorScreen(
      api: _api,
      session: _session,
      onLoggedOut: () => setState(() => _loggedIn = false),
    );
  }
}
