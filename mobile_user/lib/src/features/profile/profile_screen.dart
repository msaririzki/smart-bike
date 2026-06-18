import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.api,
    required this.onLogout,
    this.showScaffold = true,
    this.bottomPadding = 0,
    super.key,
  });

  final ApiClient api;
  final VoidCallback onLogout;
  final bool showScaffold;
  final double bottomPadding;

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = '-';
  String _email = '-';
  String _phone = '-';
  int? _weight;
  String _memberSince = '-';
  int _totalTrips = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await widget.api.currentUser();
      final historyData = await widget.api.rentalHistory(page: 1);

      if (!mounted) return;
      setState(() {
        _name = _readString(user['name'], fallback: 'Pengguna FlowBike');
        _email = _readString(user['email']);
        _phone = _readString(user['phone'], fallback: 'Belum diisi');
        _weight = user['weight'] != null
            ? int.tryParse(user['weight'].toString())
            : null;
        _totalTrips = (historyData['total'] as num?)?.toInt() ?? 0;

        // Simple member since formatting
        final createdAt = DateTime.tryParse(user['created_at'] ?? '');
        if (createdAt != null) {
          _memberSince =
              'Member sejak ${createdAt.day}/${createdAt.month}/${createdAt.year}';
        } else {
          _memberSince = 'Member aktif';
        }

        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data profil.';
        _isLoading = false;
      });
    }
  }

  String _readString(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return fallback;
    }
    return text;
  }

  bool get _canResetPassword => _email != '-' && _email.contains('@');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showEditProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return _EditProfileSheet(
          api: widget.api,
          name: _name,
          email: _email,
          phone: _phone,
          onSaved: () {
            _showMessage('Profil berhasil diperbarui');
            loadProfile();
          },
          buildInputDecoration: _buildInputDecoration,
        );
      },
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xff64748b),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 22),
      filled: true,
      fillColor: const Color(0xfff8fafc),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xfff1f5f9), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Future<void> _showPasswordResetSheet() async {
    if (!_canResetPassword) {
      _showMessage('Email akun belum tersedia untuk reset password.');
      return;
    }

    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var isCodeSent = false;
    var isBusy = false;
    String? sheetError;
    String? sheetMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> requestCode() async {
              setSheetState(() {
                isBusy = true;
                sheetError = null;
                sheetMessage = null;
              });

              try {
                await widget.api.requestPasswordReset(email: _email);
                setSheetState(() {
                  isCodeSent = true;
                  sheetMessage = 'Kode verifikasi telah dikirim ke email Anda.';
                });
              } on ApiException catch (e) {
                setSheetState(() {
                  sheetError = e.message;
                  isBusy = false;
                });
              } catch (_) {
                setSheetState(() {
                  sheetError = 'Gagal mengirim kode';
                  isBusy = false;
                });
              } finally {
                setSheetState(() => isBusy = false);
              }
            }

            Future<void> confirmReset() async {
              if (passwordController.text != confirmController.text) {
                setSheetState(
                  () => sheetError = 'Konfirmasi password tidak cocok',
                );
                return;
              }

              setSheetState(() {
                isBusy = true;
                sheetError = null;
              });

              try {
                await widget.api.confirmPasswordReset(
                  email: _email,
                  token: codeController.text.trim(),
                  password: passwordController.text,
                  passwordConfirmation: confirmController.text,
                );

                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                _showMessage(
                  'Password berhasil diubah. Silakan masuk kembali.',
                );
                widget.onLogout();
              } on ApiException catch (e) {
                setSheetState(() {
                  sheetError = e.message;
                  isBusy = false;
                });
              } catch (_) {
                setSheetState(() {
                  sheetError = 'Gagal mengubah password';
                  isBusy = false;
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCodeSent
                            ? 'Masukkan kode yang Anda terima dan password baru.'
                            : 'Kami akan mengirimkan kode verifikasi ke email Anda.',
                        style: const TextStyle(
                          color: Color(0xff64748b),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (sheetError != null) ...[
                        _SheetBanner(
                          icon: Icons.error_outline_rounded,
                          message: sheetError!,
                          color: Colors.red,
                          backgroundColor: const Color(0xfffff1f2),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (sheetMessage != null) ...[
                        _SheetBanner(
                          icon: Icons.check_circle_outline_rounded,
                          message: sheetMessage!,
                          color: AppColors.primaryLight,
                          backgroundColor: const Color(0xffecfdf5),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!isCodeSent)
                        FilledButton(
                          onPressed: isBusy ? null : requestCode,
                          child: isBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim Kode Verifikasi'),
                        )
                      else ...[
                        TextField(
                          controller: codeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Kode Verifikasi (6 Digit)',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password Baru',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Password',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: isBusy ? null : confirmReset,
                          child: isBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan Password Baru'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
  }

  String get _initials {
    if (_name == '-') return '?';
    final parts = _name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          )
        : RefreshIndicator(
            onRefresh: loadProfile,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + widget.bottomPadding,
              ),
              children: [
                _ProfileHero(
                  initials: _initials,
                  name: _name,
                  email: _email,
                  memberSince: _memberSince,
                  onEdit: _showEditProfileSheet,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _SheetBanner(
                    icon: Icons.error_outline_rounded,
                    message: _error!,
                    color: Theme.of(context).colorScheme.error,
                    backgroundColor: const Color(0xfffff1f2),
                  ),
                ],
                const SizedBox(height: 24),
                _ProfileMetricsGrid(totalTrips: _totalTrips),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'Akun & Profil'),
                _ProfilePanel(
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.person_rounded,
                      title: 'Detail Profil',
                      subtitle: _name,
                      iconBgColor: const Color(0xffeff6ff),
                      iconColor: const Color(0xff3b82f6),
                      onTap: _showEditProfileSheet,
                    ),
                    _MenuDivider(),
                    _ProfileInfoTile(
                      icon: Icons.phone_rounded,
                      title: 'Nomor Telepon',
                      subtitle: _phone,
                      iconBgColor: const Color(0xfff5f3ff),
                      iconColor: const Color(0xff8b5cf6),
                      onTap: _showEditProfileSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Keamanan'),
                _ProfilePanel(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.lock_rounded,
                      title: 'Ubah Password',
                      subtitle: 'Ganti kata sandi secara berkala',
                      iconBgColor: const Color(0xfffff7ed),
                      iconColor: const Color(0xfff97316),
                      onTap: _canResetPassword ? _showPasswordResetSheet : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfilePanel(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar Akun',
                      subtitle: 'Sesi akan berakhir di perangkat ini',
                      iconBgColor: const Color(0xfffef2f2),
                      iconColor: const Color(0xffef4444),
                      textColor: const Color(0xffef4444),
                      showChevron: false,
                      onTap: widget.onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'FlowBike v1.0.0',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );

    if (!widget.showScaffold) return body;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.api,
    required this.name,
    required this.email,
    required this.phone,
    required this.onSaved,
    required this.buildInputDecoration,
  });

  final ApiClient api;
  final String name;
  final String email;
  final String phone;
  final VoidCallback onSaved;
  final InputDecoration Function({required String label, required IconData icon}) buildInputDecoration;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  final formKey = GlobalKey<FormState>();
  var isBusy = false;
  String? sheetError;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(
      text: widget.phone == 'Belum diisi' ? '' : widget.phone,
    );
    nameController.addListener(_onControllerChanged);
    emailController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.removeListener(_onControllerChanged);
    emailController.removeListener(_onControllerChanged);
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String get initials {
    final name = nameController.text.trim();
    if (name.isEmpty || name == '-') return '?';
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isBusy = true;
      sheetError = null;
    });

    try {
      await widget.api.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } on ApiException catch (e) {
      setState(() {
        sheetError = e.message;
        isBusy = false;
      });
    } catch (e) {
      setState(() {
        sheetError = 'Gagal menyimpan perubahan';
        isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xffcbd5e1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ubah Profil',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff0f172a),
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xff64748b)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xfff1f5f9),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.05),
                      AppColors.primaryLight.withValues(alpha: 0.01),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nameController.text.trim().isEmpty
                                ? 'Nama Anda'
                                : nameController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff0f172a),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emailController.text.trim().isEmpty
                                ? 'Email Anda'
                                : emailController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff64748b),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (sheetError != null) ...[
                _SheetBanner(
                  icon: Icons.error_outline_rounded,
                  message: sheetError!,
                  color: Colors.red,
                  backgroundColor: const Color(0xfffff1f2),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'NAMA LENGKAP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff475569),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: widget.buildInputDecoration(
                  label: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'EMAIL AKUN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff475569),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: widget.buildInputDecoration(
                  label: 'Masukkan alamat email',
                  icon: Icons.alternate_email_rounded,
                ),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Email tidak valid'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'NOMOR TELEPON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff475569),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: widget.buildInputDecoration(
                  label: 'Masukkan nomor telepon (opsional)',
                  icon: Icons.phone_android_rounded,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: isBusy ? null : saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.memberSince,
    required this.onEdit,
  });

  final String initials;
  final String name;
  final String email;
  final String memberSince;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -320,
            top: 60,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/flowbike4.svg',
                width: 550,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        memberSince,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetBanner extends StatelessWidget {
  const _SheetBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetricsGrid extends StatelessWidget {
  const _ProfileMetricsGrid({required this.totalTrips});
  final int totalTrips;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileMetric(
            label: 'Trip Selesai',
            value: totalTrips.toString(),
            icon: Icons.directions_bike_rounded,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _ProfileMetric(
            label: 'Status Akun',
            value: 'Aktif',
            icon: Icons.verified_user_rounded,
            color: Color(0xff10b981),
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xfff1f5f9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff1e293b),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xff94a3b8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xfff1f5f9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1e293b),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff64748b),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xffcbd5e1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    this.onTap,
    this.textColor = const Color(0xff1e293b),
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final Color textColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff64748b),
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xffcbd5e1),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: const Color(0xfff1f5f9), height: 1),
    );
  }
}
