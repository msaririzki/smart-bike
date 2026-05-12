import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IdleWarningDialog extends StatelessWidget {
  const IdleWarningDialog({
    super.key,
    required this.onContinue,
    required this.onFinish,
    this.isLoading = false,
    this.idleWarningSeconds,
    this.idleBillingAmount,
    this.idleBillingIntervalSeconds,
    this.errorMessage,
  });

  /// Callback saat user pilih "Lanjutkan Sewa"
  final VoidCallback onContinue;

  /// Callback saat user pilih "Selesaikan Sewa"
  final VoidCallback onFinish;

  /// True saat sedang mengirim request ke server
  final bool isLoading;

  /// Durasi idle sebelum warning (detik), dari backend setting
  final int? idleWarningSeconds;

  /// Biaya idle per interval (rupiah), dari backend setting
  final int? idleBillingAmount;

  /// Interval penagihan idle (detik), dari backend setting
  final int? idleBillingIntervalSeconds;

  /// Pesan error yang ditampilkan jika ada kegagalan
  final String? errorMessage;

  String get _idleDurationText {
    final seconds = idleWarningSeconds;
    if (seconds == null || seconds <= 0) {
      return 'beberapa waktu';
    }
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      return '$hours jam';
    }
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      return '$minutes menit';
    }
    return '$seconds detik';
  }

  String? get _idleCostText {
    final amount = idleBillingAmount;
    final interval = idleBillingIntervalSeconds;
    if (amount == null || amount <= 0) {
      return null;
    }

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final formatted = currency.format(amount);

    if (interval != null && interval > 0) {
      final intervalMin = interval >= 60
          ? '${interval ~/ 60} menit'
          : '$interval detik';
      return '$formatted per $intervalMin';
    }
    return '$formatted per interval';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated warning icon.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.shade300,
                    Colors.deepOrange.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),

            // Title.
            const Text(
              'Sepeda Diam!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xff1e293b),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle dinamis.
            Text(
              'Sepeda Anda tidak bergerak selama $_idleDurationText terakhir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Info card.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.orange.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.shade200.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Jika Anda memilih Lanjutkan, biaya idle akan dikenakan selama sepeda masih diam.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Biaya idle per interval.
                  if (_idleCostText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 18,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tarif idle: $_idleCostText',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Error message.
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 18, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons.
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Memproses...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Lanjutkan button (primary)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff0f766e), Color(0xff0d9488)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0f766e).withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22),
                        label: const Text(
                          'Lanjutkan Sewa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selesaikan button (secondary/danger)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onFinish,
                      icon: Icon(Icons.stop_circle_outlined,
                          color: Colors.red.shade400, size: 20),
                      label: Text(
                        'Selesaikan Sewa',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.red.shade200,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
