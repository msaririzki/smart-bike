import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/rental.dart';
import 'idle_badge_widget.dart';
import 'map_widget.dart';

class ActiveRentalDetail extends StatelessWidget {
  const ActiveRentalDetail({
    required this.rental,
    required this.currency,
    required this.duration,
    required this.routePoints,
    required this.isFinishing,
    required this.onFinish,
    super.key,
  });

  final Rental rental;
  final NumberFormat currency;
  final Duration duration;
  final List<LatLng> routePoints;
  final bool isFinishing;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bike = rental.bike;
    final speed = rental.currentSpeedKmh ?? 0;
    final latitude = rental.latitude;
    final longitude = rental.longitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHeader(status: rental.status),
        const SizedBox(height: 16),
        _BikePanel(
          code: bike?.code ?? 'Bike',
          name: bike?.name ?? 'Sepeda',
        ),
        const SizedBox(height: 16),
        if (latitude != null && longitude != null) ...[
          SizedBox(
            height: 250,
            child: MapWidget(
              latitude: latitude,
              longitude: longitude,
              routePoints: routePoints,
              accuracyRadius: rental.gpsAccuracyMeters ?? 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Lokasi: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xff667085),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const _LocationUnavailableCard(),
          const SizedBox(height: 16),
        ],
        _ConnectionPanel(rental: rental),
        const SizedBox(height: 16),
        _MetricGrid(
          children: [
            _MetricCard(
              icon: Icons.route,
              label: 'Total Jarak',
              value: '${rental.totalDistanceKilometers.toStringAsFixed(2)} km',
              helper: '${rental.totalDistanceMeters.toStringAsFixed(1)} m',
            ),
            _MetricCard(
              icon: Icons.speed,
              label: 'Kecepatan',
              value: '${speed.toStringAsFixed(1)} km/h',
              helper: 'Terkini',
            ),
            _MetricCard(
              icon: Icons.timer_outlined,
              label: 'Durasi',
              value: _formatDuration(duration),
              helper: 'Berjalan',
            ),
            _MetricCard(
              icon: Icons.payments_outlined,
              label: 'Biaya Jarak',
              value: currency.format(rental.distanceCost),
              helper: 'Distance billing',
            ),
            _MetricCard(
              icon: Icons.hourglass_bottom,
              label: 'Biaya Idle',
              value: currency.format(rental.idleCost),
              helper: 'Idle billing',
            ),
            _MetricCard(
              icon: Icons.receipt_long,
              label: 'Total Biaya',
              value: currency.format(rental.totalCost),
              helper: 'Akumulasi',
              emphasized: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: isFinishing ? null : onFinish,
          icon: isFinishing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.stop_circle_outlined),
          label: Text(isFinishing ? 'Menyelesaikan...' : 'Selesaikan Sewa'),
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

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(style.icon, color: style.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Rental',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  style.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: status),
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
        background: Color(0xfffffaeb),
        border: Color(0xfffedf89),
      ),
      'idle_billing' => const _StatusStyle(
        label: 'IDLE BILLING',
        icon: Icons.hourglass_bottom,
        foreground: Color(0xffc2410c),
        background: Color(0xfffff7ed),
        border: Color(0xffffb27a),
      ),
      _ => const _StatusStyle(
        label: 'ACTIVE',
        icon: Icons.check_circle_outline,
        foreground: Color(0xff027a48),
        background: Color(0xffecfdf3),
        border: Color(0xffabefc6),
      ),
    };
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}

class _BikePanel extends StatelessWidget {
  const _BikePanel({required this.code, required this.name});

  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xffccfbf1),
            child: Icon(Icons.pedal_bike, color: Color(0xff0f766e)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xff0f766e),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(name, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
                  'Rental aktif sudah ditemukan, tetapi simulator belum mengirim latitude dan longitude yang bisa ditampilkan di peta.',
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

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) {
    final lastUpdate = rental.lastLocationUpdateAt;
    final networkType = rental.networkType;
    final accuracy = rental.gpsAccuracyMeters;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _ConnectionRow(
            icon: Icons.update,
            label: 'Last update',
            value: lastUpdate == null
                ? 'Belum ada data GPS'
                : DateFormat('HH:mm:ss, dd MMM yyyy').format(lastUpdate),
          ),
          const SizedBox(height: 10),
          _ConnectionRow(
            icon: Icons.network_cell_outlined,
            label: 'Network',
            value: (networkType == null || networkType.isEmpty)
                ? 'Tidak tersedia'
                : networkType,
          ),
          if (accuracy != null) ...[
            const SizedBox(height: 10),
            _ConnectionRow(
              icon: Icons.gps_fixed,
              label: 'Akurasi GPS',
              value: '${accuracy.toStringAsFixed(1)} m',
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff0f766e)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 3 ? 1.8 : 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xfff0fdfa) : Colors.white,
        border: Border.all(
          color: emphasized ? const Color(0xff5eead4) : const Color(0xffd0d5dd),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                emphasized ? const Color(0xff0f766e) : const Color(0xff475467),
          ),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xff667085)),
          ),
        ],
      ),
    );
  }
}
