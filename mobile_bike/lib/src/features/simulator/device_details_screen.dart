import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/device_rental_summary.dart';
import '../../services/api_client.dart';
import 'qr_rental_panel.dart';

class DeviceDetailsScreen extends StatelessWidget {
  const DeviceDetailsScreen({
    required this.api,
    required this.bike,
    required this.rental,
    required this.displaySpeed,
    required this.batteryPercent,
    required this.networkType,
    required this.pointsSent,
    required this.lastSentAt,
    required this.locationMode,
    required this.streaming,
    required this.now,
    required this.locationAccessGranted,
    required this.locationAccessStatus,
    required this.lastGpsReadAt,
    required this.accuracyMeters,
    super.key,
  });

  final ApiClient api;
  final Bike bike;
  final ActiveBikeRental? rental;
  final double displaySpeed;
  final int batteryPercent;
  final String networkType;
  final int pointsSent;
  final DateTime? lastSentAt;
  final String locationMode;
  final bool streaming;
  final DateTime now;
  final bool locationAccessGranted;
  final dynamic locationAccessStatus;
  final DateTime? lastGpsReadAt;
  final double? accuracyMeters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text('Detail Perangkat & Rental'),
        backgroundColor: const Color(0xFF2F9E38),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          QrRentalPanel(
            api: api,
            hasAssignedBike: true,
            hasActiveRental: rental != null,
          ),
          const SizedBox(height: 12),
          _CompactStatsRow(
            speedKmh: displaySpeed,
            rentalActive: rental != null,
            distanceKm: rental?.totalDistanceKilometers ?? 0,
            totalCost: rental?.totalCost ?? 0,
          ),
          const SizedBox(height: 12),
          _DeviceAndRentalSummary(
            bike: bike,
            rental: rental,
            batteryPercent: batteryPercent,
            networkType: networkType,
            pointsSent: pointsSent,
            lastSentAt: lastSentAt,
            locationMode: locationMode,
            streaming: streaming,
            now: now,
          ),
          const SizedBox(height: 12),
          _FieldTestChecklist(
            locationAccess: locationAccessGranted,
            gpsEnabled: locationAccessStatus.toString() !=
                'LocationAccessStatus.serviceDisabled',
            autoStart: streaming,
            networkType: networkType,
            lastGpsAt: lastGpsReadAt,
            lastServerAt: lastSentAt,
            accuracyMeters: accuracyMeters,
            rentalActive: rental != null,
          ),
        ],
      ),
    );
  }
}

class _CompactStatsRow extends StatelessWidget {
  const _CompactStatsRow({
    required this.speedKmh,
    required this.rentalActive,
    required this.distanceKm,
    required this.totalCost,
  });

  final double speedKmh;
  final bool rentalActive;
  final double distanceKm;
  final int totalCost;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SPEED',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      speedKmh.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: _Panel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            backgroundColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFFA5D6A7),
            child: Column(
              children: [
                _CompactInfoRow(
                  label: 'DISTANCE',
                  value: '${distanceKm.toStringAsFixed(2)} km',
                  icon: Icons.route_outlined,
                ),
                const Divider(height: 12, color: Color(0xFFC8E6C9)),
                _CompactInfoRow(
                  label: 'TOTAL COST',
                  value: _formatRupiah(totalCost),
                  icon: Icons.payments_outlined,
                  emphasized: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color:
                emphasized ? const Color(0xFF2F9E38) : const Color(0xFF667085)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF667085)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 14 : 12,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            color:
                emphasized ? const Color(0xFF1F4D30) : const Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}

class _DeviceAndRentalSummary extends StatelessWidget {
  const _DeviceAndRentalSummary({
    required this.bike,
    required this.rental,
    required this.batteryPercent,
    required this.networkType,
    required this.pointsSent,
    required this.lastSentAt,
    required this.locationMode,
    required this.streaming,
    required this.now,
  });

  final Bike bike;
  final ActiveBikeRental? rental;
  final int batteryPercent;
  final String networkType;
  final int pointsSent;
  final DateTime? lastSentAt;
  final String locationMode;
  final bool streaming;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pedal_bike_rounded,
                  size: 18, color: Color(0xFF2F9E38)),
              const SizedBox(width: 8),
              Text(
                '${bike.code} - ${bike.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                    fontSize: 13),
              ),
              const Spacer(),
              if (rental != null)
                _Badge(label: _rentalStatusLabel(rental!.status)),
            ],
          ),
          const Divider(height: 16),
          _MetricGridCompact(
            children: [
              _MetricItemSmall(
                  label: 'Baterai',
                  value: '$batteryPercent%',
                  icon: Icons.battery_std),
              _MetricItemSmall(
                  label: 'Jaringan',
                  value: networkType,
                  icon: Icons.network_check),
              _MetricItemSmall(
                  label: 'Titik', value: '$pointsSent', icon: Icons.upload),
              _MetricItemSmall(
                  label: 'Mode',
                  value: locationMode,
                  icon: Icons.explore_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGridCompact extends StatelessWidget {
  const _MetricGridCompact({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }
}

class _MetricItemSmall extends StatelessWidget {
  const _MetricItemSmall(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF667085))),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828))),
      ],
    );
  }
}

class _FieldTestChecklist extends StatelessWidget {
  const _FieldTestChecklist({
    required this.locationAccess,
    required this.gpsEnabled,
    required this.autoStart,
    required this.networkType,
    required this.lastGpsAt,
    required this.lastServerAt,
    required this.accuracyMeters,
    required this.rentalActive,
  });

  final bool locationAccess;
  final bool gpsEnabled;
  final bool autoStart;
  final String networkType;
  final DateTime? lastGpsAt;
  final DateTime? lastServerAt;
  final double? accuracyMeters;
  final bool rentalActive;

  @override
  Widget build(BuildContext context) {
    final accuracyOk = accuracyMeters != null && accuracyMeters! <= 50;
    final gpsFresh = _isFresh(lastGpsAt, const Duration(seconds: 15));
    final serverFresh = _isFresh(lastServerAt, const Duration(seconds: 15));

    return _Panel(
      borderColor: const Color(0xFFD0D5DD),
      backgroundColor: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist Tes Lapangan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            ok: locationAccess,
            label: 'Izin lokasi',
            detail: locationAccess ? 'Diizinkan' : 'Belum diizinkan',
          ),
          _CheckRow(
            ok: gpsEnabled,
            label: 'GPS perangkat',
            detail: gpsEnabled ? 'Aktif' : 'GPS HP belum aktif',
          ),
          _CheckRow(
            ok: autoStart,
            label: 'Tracking otomatis',
            detail: autoStart ? 'Berjalan' : 'Belum berjalan',
          ),
          _CheckRow(
            ok: networkType != 'Offline',
            label: 'Jaringan',
            detail: networkType,
          ),
          _CheckRow(
            ok: gpsFresh,
            label: 'GPS dibaca',
            detail: _relativeTimeLabel(lastGpsAt),
          ),
          _CheckRow(
            ok: serverFresh,
            label: 'Server menerima',
            detail: _relativeTimeLabel(lastServerAt),
          ),
          _CheckRow(
            ok: accuracyOk,
            label: 'Akurasi GPS',
            detail: accuracyMeters == null
                ? 'Belum ada data'
                : '${accuracyMeters!.toStringAsFixed(0)} m',
          ),
          _CheckRow(
            ok: rentalActive,
            label: 'Rental aktif',
            detail: rentalActive ? 'Ada rental berjalan' : 'Monitoring saja',
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.ok,
    required this.label,
    required this.detail,
  });

  final bool ok;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF027A48) : const Color(0xFFB54708);
    final background = ok ? const Color(0xFFECFDF3) : const Color(0xFFFFFAEB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration:
                BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(
              ok ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFABEFC6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF027A48),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatRupiah(int value) {
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${value < 0 ? '-' : ''}Rp${buffer.toString()}';
}

String _timeDiff(DateTime dt) {
  final rawDiff = DateTime.now().difference(dt);
  final diff = rawDiff.isNegative ? Duration.zero : rawDiff;
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  return '${diff.inHours}j';
}

String _relativeTimeLabel(DateTime? dt) {
  if (dt == null) return 'Belum ada';
  return '${_timeDiff(dt)} lalu';
}

bool _isFresh(DateTime? dt, Duration maxAge) {
  if (dt == null) return false;
  final age = DateTime.now().difference(dt);
  return !age.isNegative && age <= maxAge;
}

String _rentalStatusLabel(String status) {
  return switch (status) {
    'active' => 'Aktif',
    'idle_warning' => 'Peringatan Diam',
    'idle_billing' => 'Biaya Diam',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}
