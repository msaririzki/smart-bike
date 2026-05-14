import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.api, required this.onLoggedIn, super.key});

  final ApiClient api;
  final VoidCallback onLoggedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'user@smartbike.test');
  final _passwordController = TextEditingController(text: 'password');

  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await widget.api.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.api.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      widget.onLoggedIn();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Tidak bisa terhubung ke backend.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xfff1f5f9)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        'assets/flowbike3.svg',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                          children: [
                            TextSpan(text: 'Flow', style: TextStyle(color: Color(0xFF349665))),
                            TextSpan(text: 'Bike', style: TextStyle(color: Color(0xFF133C36))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ride Smooth. Track Smart.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isRegister) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                            ),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.mail_outline),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || !value.contains('@') ? 'Email tidak valid.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) => value == null || value.length < 6 ? 'Minimal 6 karakter.' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xfffef2f2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xfffecaca)),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
                            : Icon(_isRegister ? Icons.person_add_alt : Icons.login),
                        label: Text(_isRegister ? 'Daftar' : 'Login'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _isRegister = !_isRegister;
                                  _error = null;
                                }),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xff64748b)),
                        child: Text(
                          _isRegister ? 'Sudah punya akun? Login' : 'Belum punya akun? Daftar',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
