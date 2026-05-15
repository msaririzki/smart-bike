import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/rental.dart';
import 'map_widget.dart';
import 'package:mobile_user/src/theme/app_colors.dart';

class ActiveRentalDetail extends StatelessWidget {
  const ActiveRentalDetail({
    required this.rental,
    required this.currency,
    required this.duration,
    required this.routePoints,
    this.idleBillingAmount,
    this.idleBillingIntervalSeconds,
    super.key,
  });

  final Rental rental;
  final NumberFormat currency;
  final Duration duration;
  final List<LatLng> routePoints;
  final int? idleBillingAmount;
  final int? idleBillingIntervalSeconds;

  @override
  Widget build(BuildContext context) {
    final bike = rental.bike;
    final speed = rental.currentSpeedKmh;
    final latitude = rental.latitude;
    final longitude = rental.longitude;
    final screenSize = MediaQuery.sizeOf(context);
    final compact = screenSize.width < 380 || screenSize.height < 720;
    final mapHeight = compact ? 176.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BikeStatusPanel(
          code: bike?.code ?? 'Bike',
          name: bike?.name ?? 'Sepeda',
          status: rental.status,
        ),
        if (rental.status == 'idle_billing') ...[
          const SizedBox(height: 10),
          _IdleBillingExplanation(
            currency: currency,
            billingAmount: idleBillingAmount,
            intervalSeconds: idleBillingIntervalSeconds,
          ),
        ],
        const SizedBox(height: 14),
        if (latitude != null && longitude != null) ...[
          SizedBox(
            height: mapHeight,
            child: MapWidget(
              latitude: latitude,
              longitude: longitude,
              routePoints: routePoints,
              accuracyRadius: rental.gpsAccuracyMeters ?? 0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: Color(0xff6b7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xff6b7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (routePoints.length >= 2) ...[
            const SizedBox(height: 4),
            Text(
              'Jalur di peta adalah ringkasan titik GPS yang dikirim perangkat sepeda.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
        ] else ...[
          const _LocationUnavailableCard(),
          const SizedBox(height: 14),
        ],
        _RentalDataPanel(
          rental: rental,
          currency: currency,
          duration: duration,
          speed: speed,
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return [
        hours.toString().padLeft(2, '0'),
        minutes.toString().padLeft(2, '0'),
        seconds.toString().padLeft(2, '0'),
      ].join(':');
    }

    return [
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');
  }
}

class _BikeStatusPanel extends StatelessWidget {
  const _BikeStatusPanel({
    required this.code,
    required this.name,
    required this.status,
  });

  final String code;
  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.pedal_bike, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFa7c4b8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(child: _CompactStatusPill(style: style)),
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    return switch (status) {
      'idle_warning' => const _StatusStyle(
        label: 'IDLE WARNING',
        icon: Icons.warning_amber_rounded,
        foreground: Color(0xffb54708),
      ),
      'idle_billing' => const _StatusStyle(
        label: 'IDLE BILLING',
        icon: Icons.hourglass_bottom,
        foreground: Color(0xffc2410c),
      ),
      _ => const _StatusStyle(
        label: 'AKTIF',
        icon: Icons.check_circle_outline,
        foreground: Color(0xffbbf7d0),
      ),
    };
  }
}

class _CompactStatusPill extends StatelessWidget {
  const _CompactStatusPill({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.foreground),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.foreground,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color foreground;
}

class _LocationUnavailableCard extends StatelessWidget {
  const _LocationUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffffaeb),
        border: Border.all(color: const Color(0xfffedf89)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_off_outlined, color: Color(0xffb54708)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koordinat belum tersedia',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xff93370d),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rental aktif sudah ditemukan, tetapi perangkat mobile_bike belum mengirim latitude dan longitude yang bisa ditampilkan di peta.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xff93370d),
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

class _RentalDataPanel extends StatelessWidget {
  const _RentalDataPanel({
    required this.rental,
    required this.currency,
    required this.duration,
    required this.speed,
  });

  final Rental rental;
  final NumberFormat currency;
  final Duration duration;
  final double speed;

  @override
  Widget build(BuildContext context) {
    final lastUpdate = rental.lastLocationUpdateAt;
    final networkType = rental.networkType;
    final accuracy = rental.gpsAccuracyMeters;
    final lastUpdateText = lastUpdate == null
        ? 'Belum ada data GPS'
        : '${DateFormat('HH:mm:ss').format(lastUpdate)} (${_formatRelativeTime(lastUpdate)})';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe5e7eb)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff133c36).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              'Detail Sewa',
              style: TextStyle(
                color: Color(0xff133c36),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TotalCostHighlight(
            total: currency.format(rental.totalCost),
            distanceCost: currency.format(rental.distanceCost),
            idleCost: currency.format(rental.idleCost),
          ),
          const SizedBox(height: 12),
          _GpsQualityBadge(accuracy: accuracy),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.timer_outlined,
            label: 'Durasi',
            value: ActiveRentalDetail._formatDuration(duration),
          ),
          const _DataDivider(),
          _DetailRow(
            icon: Icons.route_rounded,
            label: 'Total jarak',
            value: '${rental.totalDistanceKilometers.toStringAsFixed(2)} km',
            helper: '${rental.totalDistanceMeters.toStringAsFixed(1)} m',
          ),
          const _DataDivider(),
          _DetailRow(
            icon: Icons.speed_rounded,
            label: 'Kecepatan',
            value: '${speed.toStringAsFixed(1)} km/h',
          ),
          const _DataDivider(),
          _DetailRow(
            icon: Icons.update_rounded,
            label: 'GPS terakhir',
            value: lastUpdateText,
          ),
          const _DataDivider(),
          _DetailRow(
            icon: Icons.network_cell_outlined,
            label: 'Network',
            value: (networkType == null || networkType.isEmpty)
                ? 'Tidak tersedia'
                : networkType,
          ),
          if (accuracy != null) ...[
            const _DataDivider(),
            _DetailRow(
              icon: Icons.gps_fixed_rounded,
              label: 'Akurasi',
              value: '${accuracy.toStringAsFixed(1)} m',
            ),
          ],
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.isNegative || diff.inSeconds < 5) {
      return 'Baru saja';
    }
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik lalu';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    return '${diff.inDays} hari lalu';
  }
}

class _TotalCostHighlight extends StatelessWidget {
  const _TotalCostHighlight({
    required this.total,
    required this.distanceCost,
    required this.idleCost,
  });

  final String total;
  final String distanceCost;
  final String idleCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffbbf7d0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Total biaya berjalan',
                  style: TextStyle(
                    color: Color(0xff1f4d30),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total,
              style: const TextStyle(
                color: Color(0xff133c36),
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CostChip(label: 'Jarak', value: distanceCost),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CostChip(label: 'Idle', value: idleCost),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffdcfce7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff6b7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff133c36),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsQualityBadge extends StatelessWidget {
  const _GpsQualityBadge({required this.accuracy});

  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    final accuracy = this.accuracy;
    final (label, color, background, icon) = switch (accuracy) {
      null => (
        'GPS Belum Tersedia',
        const Color(0xff667085),
        const Color(0xfff2f4f7),
        Icons.gps_off,
      ),
      <= 25 => (
        'GPS Akurat',
        const Color(0xff027a48),
        const Color(0xffecfdf3),
        Icons.gps_fixed,
      ),
      _ => (
        'GPS Kurang Akurat',
        const Color(0xffb54708),
        const Color(0xfffffaeb),
        Icons.gps_not_fixed,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              accuracy == null
                  ? label
                  : '$label (${accuracy.toStringAsFixed(1)} m)',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataDivider extends StatelessWidget {
  const _DataDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xffedf0f2)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xffecfdf5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xff4b5563),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                Text(
                  helper!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xff6b7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IdleBillingExplanation extends StatelessWidget {
  const _IdleBillingExplanation({
    required this.currency,
    this.billingAmount,
    this.intervalSeconds,
  });

  final NumberFormat currency;
  final int? billingAmount;
  final int? intervalSeconds;

  @override
  Widget build(BuildContext context) {
    String rateText = 'Biaya idle sedang berjalan.';
    if (billingAmount != null && billingAmount! > 0) {
      final formatted = currency.format(billingAmount);
      if (intervalSeconds != null && intervalSeconds! > 0) {
        final intervalLabel = intervalSeconds! >= 60
            ? '${intervalSeconds! ~/ 60} menit'
            : '$intervalSeconds detik';
        rateText = 'Biaya idle sedang berjalan, $formatted per $intervalLabel.';
      } else {
        rateText = 'Biaya idle sedang berjalan, $formatted per interval.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.monetization_on_outlined,
              size: 22,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idle Billing Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rateText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    height: 1.3,
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
