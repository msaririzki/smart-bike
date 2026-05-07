import 'package:flutter/material.dart';
import 'idle_warning_dialog.dart';
import 'idle_badge_widget.dart';

/// Screen ini HANYA untuk testing — hapus setelah integrasi dengan Riki
class IdleTestScreen extends StatefulWidget {
  const IdleTestScreen({super.key});
  @override
  State<IdleTestScreen> createState() => _IdleTestScreenState();
}

class _IdleTestScreenState extends State<IdleTestScreen> {
  String _status = 'active';
  bool _isLoading = false;

  void _simulateIdleWarning() {
    setState(() => _status = 'idle_warning');
    _showIdleDialog();
  }

  void _showIdleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => IdleWarningDialog(
        isLoading: _isLoading,
        onContinue: () {
          setState(() => _isLoading = true);
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pop();
            setState(() {
              _isLoading = false;
              _status = 'idle_billing';
            });
          });
        },
        onFinish: () {
          Navigator.of(context).pop();
          setState(() => _status = 'active');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Sewa berhasil diselesaikan'),
                ],
              ),
              backgroundColor: const Color(0xff059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = parseRentalStatus(_status);
    final statusDescription = switch (parsed) {
      RentalStatus.active =>
        'Sepeda sedang aktif digunakan. Biaya dihitung berdasarkan jarak tempuh.',
      RentalStatus.idleWarning =>
        'Sepeda tidak bergerak selama 5 menit. Menunggu keputusan pengguna.',
      RentalStatus.idleBilling =>
        'Pengguna memilih lanjut. Biaya idle sedang berjalan.',
      RentalStatus.other => 'Status tidak diketahui.',
    };

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text(
          'Test Idle Warning',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1e293b),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0f766e), Color(0xff14b8a6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0f766e).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.pedal_bike, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Simulasi Idle Detection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uji tampilan dialog peringatan & badge status',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Status display card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Status Rental Saat Ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  StatusBadge(status: _status),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            statusDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Control section title ──
            Text(
              'KONTROL SIMULASI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // ── Control buttons ──
            _SimulationButton(
              icon: Icons.play_circle_filled,
              label: 'Set Status: Active',
              subtitle: 'Sepeda aktif bergerak',
              color: const Color(0xff059669),
              onTap: () => setState(() => _status = 'active'),
            ),
            const SizedBox(height: 10),
            _SimulationButton(
              icon: Icons.warning_amber_rounded,
              label: 'Simulasi Idle Warning',
              subtitle: 'Tampilkan dialog peringatan idle',
              color: const Color(0xfff59e0b),
              onTap: _simulateIdleWarning,
            ),
            const SizedBox(height: 10),
            _SimulationButton(
              icon: Icons.attach_money,
              label: 'Set Status: Idle Billing',
              subtitle: 'Biaya idle sedang berjalan',
              color: const Color(0xffef4444),
              onTap: () => setState(() => _status = 'idle_billing'),
            ),
            const SizedBox(height: 28),

            // ── Footer info ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xffeff6ff),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffbfdbfe)),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined,
                      size: 18, color: Colors.blue.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Screen ini hanya untuk testing. Akan dihapus setelah integrasi dengan Riki.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tombol simulasi yang rapi dan konsisten
class _SimulationButton extends StatelessWidget {
  const _SimulationButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1e293b),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
