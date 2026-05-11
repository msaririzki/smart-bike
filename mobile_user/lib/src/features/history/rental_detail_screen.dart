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
        title: const Text('Detail Perjalanan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff073f3a),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showShareSheet(context),
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Highlight Perjalanan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BikeHeader(history: history, dateFormat: dateFormat),
            const SizedBox(height: 24),
            _RideMetricsGrid(history: history),
            const SizedBox(height: 24),
            _TripTimeline(history: history, timeFormat: timeFormat),
            const SizedBox(height: 24),
            _BillingDetailCard(history: history, currency: currency),
            const SizedBox(height: 24),
            _GreenImpactCard(history: history),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(history: history),
    );
  }
}

class _BikeHeader extends StatelessWidget {
  const _BikeHeader({required this.history, required this.dateFormat});
  final RentalHistory history;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'bike-icon-${history.id}',
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffe8f7f2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pedal_bike, color: Color(0xff23866f), size: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.bike?.code ?? 'SMART BIKE',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff073f3a)),
              ),
              Text(
                dateFormat.format(history.startedAt),
                style: const TextStyle(color: Color(0xff8a9590), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        _StatusBadge(status: history.status),
      ],
    );
  }
}

class _RideMetricsGrid extends StatelessWidget {
  const _RideMetricsGrid({required this.history});
  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MetricItem(
                label: 'Jarak',
                value: '${history.totalDistanceKilometers.toStringAsFixed(1)}',
                unit: 'km',
                icon: Icons.map_rounded,
                color: Colors.blue,
              ),
              Container(width: 1, height: 40, color: const Color(0xffe3ebe7)),
              _MetricItem(
                label: 'Durasi',
                value: '${history.durationMinutes}',
                unit: 'min',
                icon: Icons.timer_rounded,
                color: Colors.orange,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xffe3ebe7)),
          ),
          Row(
            children: [
              _MetricItem(
                label: 'Kecepatan',
                value: '${history.averageSpeed.toStringAsFixed(1)}',
                unit: 'km/j',
                icon: Icons.speed_rounded,
                color: Colors.purple,
              ),
              Container(width: 1, height: 40, color: const Color(0xffe3ebe7)),
              _MetricItem(
                label: 'Kalori',
                value: '${history.caloriesBurned.toStringAsFixed(0)}',
                unit: 'kkal',
                icon: Icons.local_fire_department_rounded,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xff073f3a)),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff8a9590)),
                  ),
                ],
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xff8a9590), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripTimeline extends StatelessWidget {
  const _TripTimeline({required this.history, required this.timeFormat});
  final RentalHistory history;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline Perjalanan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xff073f3a)),
          ),
          const SizedBox(height: 20),
          _TimelineRow(
            time: timeFormat.format(history.startedAt),
            label: 'Mulai Berkendara',
            isStart: true,
          ),
          Container(
            margin: const EdgeInsets.only(left: 11),
            height: 20,
            width: 2,
            color: const Color(0xffe3ebe7),
          ),
          _TimelineRow(
            time: history.endedAt != null ? timeFormat.format(history.endedAt!) : '-',
            label: 'Selesai Berkendara',
            isStart: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.time, required this.label, required this.isStart});
  final String time;
  final String label;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isStart ? const Color(0xff269276).withOpacity(0.1) : const Color(0xfff1f5f9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isStart ? const Color(0xff269276) : const Color(0xffcbd5e1),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isStart ? const Color(0xff269276) : const Color(0xffcbd5e1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xff073f3a)),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xff8a9590)),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Biaya',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xff073f3a)),
          ),
          const Divider(height: 32),
          _InfoRow(label: 'Biaya Jarak', value: currency.format(history.distanceCost)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Biaya Idle', value: currency.format(history.idleCost)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Biaya',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xff073f3a)),
              ),
              Text(
                currency.format(history.totalCost),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff269276)),
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

class _GreenImpactCard extends StatelessWidget {
  const _GreenImpactCard({required this.history});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    final co2Gram = history.totalDistanceKilometers * 120;
    final co2Text = co2Gram >= 1000 
        ? '${(co2Gram / 1000).toStringAsFixed(1)} kg'
        : '${co2Gram.toStringAsFixed(0)} g';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdcfce7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: Color(0xff166534), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dampak Lingkungan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamu berhasil menyelamatkan bumi dari $co2Text emisi CO2 dengan bersepeda!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff15803d),
                    height: 1.4,
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

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.history});

  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    final totalKm = history.totalDistanceKilometers;
    final totalCo2Gram = totalKm * 120;
    final co2Text = totalCo2Gram >= 1000 ? '${(totalCo2Gram / 1000).toStringAsFixed(1)}kg' : '${totalCo2Gram.toStringAsFixed(0)}g';
    final dateFormat = DateFormat('EEEE, d MMM yyyy', 'id_ID');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Highlight Perjalanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xff073f3a))),
          const SizedBox(height: 8),
          const Text('Siap dibagikan ke media sosial!', style: TextStyle(color: Color(0xff8a9590))),
          const SizedBox(height: 24),
          // THE CARD
          AspectRatio(
            aspectRatio: 0.85,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff269276).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // BACKGROUND GRADIENT
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff064e3b), Color(0xff065f46), Color(0xff047857)],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                  // ABSTRACT DECORATION
                  Positioned(
                    right: -40,
                    top: 20,
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(Icons.gesture_rounded, size: 280, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                    ),
                  ),
                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SMART BIKE',
                                  style: TextStyle(color: Color(0xff4ade80), letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  dateFormat.format(history.startedAt).toUpperCase(),
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.pedal_bike, color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'MY RIDE\nSUMMARY',
                          style: TextStyle(color: Colors.white, fontSize: 38, height: 1.0, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xff4ade80), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_rounded, size: 14, color: Color(0xff064e3b)),
                              const SizedBox(width: 6),
                              Text(
                                'SAVED $co2Text CO2',
                                style: const TextStyle(color: Color(0xff064e3b), fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ShareStatPremium(label: 'DISTANCE', value: totalKm.toStringAsFixed(1), unit: 'km'),
                            _ShareStatPremium(label: 'CALORIES', value: history.caloriesBurned.toStringAsFixed(0), unit: 'kcal'),
                            _ShareStatPremium(label: 'SPEED', value: history.averageSpeed.toStringAsFixed(1), unit: 'km/h'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Ride for a better planet, one pedal at a time.',
                            style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ShareStatPremium extends StatelessWidget {
  const _ShareStatPremium({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1),
        ),
      ],
    );
  }
}
