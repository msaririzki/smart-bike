import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_history.dart';

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
      backgroundColor: const Color(0xfff7fbf8),
      appBar: AppBar(
        title: const Text('Detail Riwayat Sewa'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff073f3a),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BikeInfoCard(history: history),
            const SizedBox(height: 20),
            _RentalSummaryCard(
              history: history,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
            ),
            const SizedBox(height: 20),
            _BillingDetailCard(history: history, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _BikeInfoCard extends StatelessWidget {
  const _BikeInfoCard({required this.history});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xffe8f7f2),
            child: Icon(Icons.pedal_bike, color: Color(0xff23866f)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.bike?.code ?? 'BIKE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff073f3a),
                  ),
                ),
                Text(
                  history.bike?.name ?? 'Unknown Bike',
                  style: const TextStyle(color: Color(0xff8a9590)),
                ),
              ],
            ),
          ),
          _StatusBadge(status: history.status),
        ],
      ),
    );
  }
}

class _RentalSummaryCard extends StatelessWidget {
  const _RentalSummaryCard({
    required this.history,
    required this.dateFormat,
    required this.timeFormat,
  });

  final RentalHistory history;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Sewa',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff073f3a),
            ),
          ),
          const Divider(height: 24),
          _InfoRow(
            label: 'Tanggal',
            value: dateFormat.format(history.startedAt),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Waktu Mulai',
            value: timeFormat.format(history.startedAt),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Waktu Selesai',
            value: history.endedAt != null
                ? timeFormat.format(history.endedAt!)
                : '-',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Durasi Total',
            value: history.durationString,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Jarak Tempuh',
            value: '${history.totalDistanceKilometers.toStringAsFixed(2)} km',
          ),
        ],
      ),
    );
  }
}

class _BillingDetailCard extends StatelessWidget {
  const _BillingDetailCard({required this.history, required this.currency});

  final RentalHistory history;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Biaya',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff073f3a),
            ),
          ),
          const Divider(height: 24),
          _InfoRow(
            label: 'Biaya Jarak',
            value: currency.format(history.distanceCost),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Biaya Idle',
            value: currency.format(history.idleCost),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Biaya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff073f3a),
                ),
              ),
              Text(
                currency.format(history.totalCost),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff269276),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff8a9590))),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff073f3a),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    final color = isCompleted ? const Color(0xff23866f) : const Color(0xffd14148);
    final bgColor = isCompleted ? const Color(0xffe8f7f2) : const Color(0xffffecef);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
