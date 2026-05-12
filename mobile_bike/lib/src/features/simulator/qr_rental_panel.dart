import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/rental_qr_session.dart';
import '../../services/api_client.dart';

class QrRentalPanel extends StatefulWidget {
  const QrRentalPanel({
    required this.api,
    required this.hasAssignedBike,
    required this.hasActiveRental,
    super.key,
  });

  final ApiClient api;
  final bool hasAssignedBike;
  final bool hasActiveRental;

  @override
  State<QrRentalPanel> createState() => _QrRentalPanelState();
}

class _QrRentalPanelState extends State<QrRentalPanel> {
  RentalQrSession? _session;
  bool _loading = false;
  String? _error;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_canShowQr) _generateQr();
  }

  @override
  void didUpdateWidget(QrRentalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasActiveRental && widget.hasActiveRental) {
      _stopTimers();
      setState(() {
        _session = null;
        _error = null;
      });
    }
    if (oldWidget.hasActiveRental && !widget.hasActiveRental && _canShowQr) {
      _generateQr();
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  bool get _canShowQr =>
      widget.hasAssignedBike && !widget.hasActiveRental;

  void _stopTimers() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _countdownTimer = null;
    _refreshTimer = null;
  }

  Future<void> _generateQr() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await widget.api.createRentalQr();
      if (!mounted) return;
      _stopTimers();
      setState(() {
        _session = session;
        _remaining = session.remainingDuration;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final remaining = _session?.remainingDuration ?? Duration.zero;
        setState(() => _remaining = remaining);
        if (remaining <= Duration.zero) {
          _stopTimers();
        }
      });

      // Auto-refresh 15 seconds before expiry
      final refreshDelay = _remaining - const Duration(seconds: 15);
      if (refreshDelay > Duration.zero) {
        _refreshTimer = Timer(refreshDelay, () {
          if (mounted && _canShowQr) _generateQr();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal membuat QR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QR Sewa Sepeda',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'User scan QR ini untuk mulai menyewa sepeda.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!widget.hasAssignedBike) {
      return _buildMessage(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFFBBF24),
        text: 'Tidak bisa membuat QR',
        subtitle: 'Belum ada sepeda yang di-assign.',
      );
    }

    if (widget.hasActiveRental) {
      return _buildMessage(
        icon: Icons.pedal_bike_rounded,
        color: const Color(0xFF22C55E),
        text: 'Sepeda sedang disewa',
        subtitle: 'QR tidak ditampilkan saat rental aktif.',
      );
    }

    if (_loading && _session == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          _buildMessage(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFEF4444),
            text: 'Gagal membuat QR',
            subtitle: _error!,
          ),
          const SizedBox(height: 12),
          _refreshButton(),
        ],
      );
    }

    final session = _session;
    if (session == null) return const SizedBox.shrink();

    final expired = _remaining <= Duration.zero;

    return Column(
      children: [
        // QR code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: expired
              ? const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_off_rounded,
                            size: 48, color: Color(0xFFEF4444)),
                        SizedBox(height: 8),
                        Text(
                          'QR Expired',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : QrImageView(
                  data: session.payload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (context, error) => const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: Text('QR Error')),
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Bike info
        Text(
          '${session.bikeCode} — ${session.bikeName}',
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Countdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: expired ? const Color(0x33EF4444) : const Color(0x3322C55E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                expired ? Icons.timer_off_rounded : Icons.timer_rounded,
                size: 16,
                color: expired
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 6),
              Text(
                expired
                    ? 'QR expired'
                    : 'Berlaku ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: expired
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Refresh button
        _refreshButton(),
      ],
    );
  }

  Widget _refreshButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _generateQr,
        icon: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 18),
        label: Text(_loading ? 'Memuat...' : 'Refresh QR'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String text,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
