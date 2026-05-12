import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/rental_history.dart';
import 'package:mobile_user/src/theme/app_colors.dart';

class RentalDetailScreen extends StatelessWidget {
  const RentalDetailScreen({required this.history, super.key});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xfff8faf8),
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        actions: [
          IconButton(
            onPressed: () => _showShareSheet(context, currency),
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Bagikan ringkasan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _TripHero(
            history: history,
            currency: currency,
            dateText: dateFormat.format(history.startedAt),
          ),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Statistik'),
          const SizedBox(height: 12),
          _MetricsSurface(history: history),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Waktu perjalanan'),
          const SizedBox(height: 12),
          _TimelineSurface(history: history, timeFormat: timeFormat),
          const SizedBox(height: 28),
          _SectionTitle(title: 'Rincian biaya'),
          const SizedBox(height: 12),
          _BillingSurface(history: history, currency: currency),
          const SizedBox(height: 28),
          _ImpactNote(history: history),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, NumberFormat currency) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ShareSheet(history: history, currency: currency),
    );
  }
}

class _TripHero extends StatelessWidget {
  const _TripHero({
    required this.history,
    required this.currency,
    required this.dateText,
  });

  final RentalHistory history;
  final NumberFormat currency;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusPill(status: history.status),
            const Spacer(),
            Text(
              history.bike?.code ?? 'SMART BIKE',
              style: const TextStyle(
                color: Color(0xff6b7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          history.totalDistanceKilometers.toStringAsFixed(1),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 0.92,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'kilometer',
          style: TextStyle(
            color: Color(0xff6b7280),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          dateText,
          style: const TextStyle(color: Color(0xff6b7280), height: 1.4),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _HeroStat(label: 'Durasi', value: history.durationString),
            ),
            Expanded(
              child: _HeroStat(
                label: 'Total',
                value: currency.format(history.totalCost),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Color(0xff6b7280))),
      ],
    );
  }
}

class _MetricsSurface extends StatelessWidget {
  const _MetricsSurface({required this.history});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        children: [
          _MetricRow(
            icon: Icons.speed_outlined,
            label: 'Kecepatan rata-rata',
            value: '${history.averageSpeed.toStringAsFixed(1)} km/j',
          ),
          const Divider(height: 24),
          _MetricRow(
            icon: Icons.local_fire_department_outlined,
            label: 'Estimasi kalori',
            value: '${history.caloriesBurned.toStringAsFixed(0)} kkal',
          ),
          const Divider(height: 24),
          _MetricRow(
            icon: Icons.route_outlined,
            label: 'Jarak tercatat',
            value: '${history.totalDistanceMeters.toStringAsFixed(0)} m',
          ),
        ],
      ),
    );
  }
}

class _TimelineSurface extends StatelessWidget {
  const _TimelineSurface({required this.history, required this.timeFormat});

  final RentalHistory history;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        children: [
          _TimelineRow(
            time: timeFormat.format(history.startedAt),
            title: 'Mulai berkendara',
            active: true,
          ),
          Container(
            margin: const EdgeInsets.only(left: 11),
            height: 26,
            width: 2,
            color: const Color(0xffe5e7eb),
          ),
          _TimelineRow(
            time: history.endedAt == null
                ? '-'
                : timeFormat.format(history.endedAt!),
            title: history.endedAt == null
                ? 'Masih berjalan'
                : 'Selesai berkendara',
            active: history.endedAt != null,
          ),
        ],
      ),
    );
  }
}

class _BillingSurface extends StatelessWidget {
  const _BillingSurface({required this.history, required this.currency});

  final RentalHistory history;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        children: [
          _AmountRow(
            label: 'Biaya jarak',
            value: currency.format(history.distanceCost),
          ),
          const SizedBox(height: 14),
          _AmountRow(
            label: 'Biaya idle',
            value: currency.format(history.idleCost),
          ),
          const Divider(height: 30),
          _AmountRow(
            label: 'Total biaya',
            value: currency.format(history.totalCost),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ImpactNote extends StatelessWidget {
  const _ImpactNote({required this.history});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    final co2Gram = history.totalDistanceKilometers * 120;
    final co2Text = co2Gram >= 1000
        ? '${(co2Gram / 1000).toStringAsFixed(1)} kg'
        : '${co2Gram.toStringAsFixed(0)} g';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.eco_outlined, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Estimasi emisi yang dihindari sekitar $co2Text CO2 dibanding perjalanan bermotor pendek.',
            style: const TextStyle(color: Color(0xff4b5563), height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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
        Icon(icon, color: AppColors.primaryLight, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xff6b7280))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.active,
  });

  final String time;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryLight : const Color(0xff9ca3af);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(time, style: const TextStyle(color: Color(0xff6b7280))),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized
                ? const Color(0xff111827)
                : const Color(0xff6b7280),
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasized
                ? AppColors.primaryLight
                : const Color(0xff111827),
            fontSize: emphasized ? 20 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isCompleted = normalized == 'completed';
    final isActive = normalized == 'active';
    final color = isCompleted || isActive
        ? AppColors.primaryLight
        : const Color(0xffdc2626);
    final label = isCompleted
        ? 'Selesai'
        : isActive
        ? 'Aktif'
        : 'Dibatalkan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.history, required this.currency});

  final RentalHistory history;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagikan ringkasan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Salin detail perjalanan dalam format singkat.',
              style: TextStyle(color: Color(0xff6b7280)),
            ),
            const SizedBox(height: 20),
            _Surface(
              child: Text(_summaryText(), style: const TextStyle(height: 1.45)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _summaryText()));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ringkasan disalin.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Salin Ringkasan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summaryText() {
    return '''
Ringkasan Smart Bike
Sepeda: ${history.bike?.code ?? 'N/A'}
Jarak: ${history.totalDistanceKilometers.toStringAsFixed(2)} km
Durasi: ${history.durationString}
Total biaya: ${currency.format(history.totalCost)}
''';
  }
}
