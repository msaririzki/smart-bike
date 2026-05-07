import 'package:flutter/material.dart';

enum RentalStatus { active, idleWarning, idleBilling, other }

/// Konversi string status dari API ke enum
RentalStatus parseRentalStatus(String status) {
  switch (status) {
    case 'active':
      return RentalStatus.active;
    case 'idle_warning':
      return RentalStatus.idleWarning;
    case 'idle_billing':
      return RentalStatus.idleBilling;
    default:
      return RentalStatus.other;
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final parsed = parseRentalStatus(status);

    final (label, gradient, textColor, icon, glowColor) = switch (parsed) {
      RentalStatus.active => (
          'AKTIF',
          const [Color(0xff059669), Color(0xff10b981)],
          Colors.white,
          Icons.play_circle_outline,
          const Color(0xff059669),
        ),
      RentalStatus.idleWarning => (
          'IDLE WARNING',
          const [Color(0xfff59e0b), Color(0xfffbbf24)],
          Colors.white,
          Icons.warning_amber_rounded,
          const Color(0xfff59e0b),
        ),
      RentalStatus.idleBilling => (
          'IDLE BILLING',
          const [Color(0xffef4444), Color(0xfff87171)],
          Colors.white,
          Icons.attach_money,
          const Color(0xffef4444),
        ),
      RentalStatus.other => (
          status.toUpperCase(),
          const [Color(0xff6b7280), Color(0xff9ca3af)],
          Colors.white,
          Icons.info_outline,
          const Color(0xff6b7280),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: textColor,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
