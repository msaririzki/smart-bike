import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.api, required this.onLoggedIn, super.key});

  final ApiClient api;
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'device@smartbike.test');
  final _passCtrl = TextEditingController(text: 'password');

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      widget.onLoggedIn();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Tidak bisa terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF22C55E),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.pedal_bike_rounded,
                        size: 40,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Smart Bike',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Device Simulator',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    _buildLabel('Email Device'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'device@smartbike.test',
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (v) =>
                          v == null || !v.contains('@') ? 'Email tidak valid.' : null,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password wajib diisi.' : null,
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Masuk sebagai Device',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22C55E)),
        ),
      );
}
