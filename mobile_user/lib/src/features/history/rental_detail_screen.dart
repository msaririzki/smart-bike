import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../models/rental_history.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../rental/map_widget.dart';

class RentalDetailScreen extends StatefulWidget {
  const RentalDetailScreen({
    required this.history,
    required this.api,
    super.key,
  });

  final RentalHistory history;
  final ApiClient api;

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  late RentalHistory _currentHistory;
  bool _isLoading = true;
  String? _detailError;
  num? _userWeight;

  @override
  void initState() {
    super.initState();
    _currentHistory = widget.history;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await widget.api.rentalDetail(widget.history.id);
      final userWeight = await widget.api.cachedUserWeight();

      if (mounted) {
        setState(() {
          _currentHistory = RentalHistory.fromJson(data);
          _userWeight = userWeight;
          _isLoading = false;
          _detailError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _detailError = 'Detail lengkap perjalanan belum bisa dimuat.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _currentHistory;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      appBar: AppBar(
        title: const Text('Detail Perjalanan'),
        backgroundColor: const Color.fromARGB(255, 253, 255, 254),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_detailError != null) ...[
                  _InlineErrorBanner(message: _detailError!),
                  const SizedBox(height: 16),
                ],
                _BikeHeader(history: history, dateFormat: dateFormat),
                const SizedBox(height: 24),
                _RentalRouteMap(history: history),
                const SizedBox(height: 24),
                _RideMetricsGrid(history: history, userWeight: _userWeight),
                const SizedBox(height: 24),
                _TripTimeline(history: history, timeFormat: timeFormat),
                const SizedBox(height: 24),
                _BillingDetailCard(history: history, currency: currency),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ShareSheet(history: _currentHistory, userWeight: _userWeight),
    );
  }
}

double _estimatedCyclingCalories(RentalHistory history, num? userWeight) {
  final durationHours = history.durationMinutes / 60.0;
  if (durationHours <= 0) return 0;

  final speed = history.averageSpeed;
  final weight = (userWeight ?? 60).toDouble();

  double met = 4.0;
  if (speed > 22) {
    met = 10.0;
  } else if (speed >= 19) {
    met = 8.0;
  } else if (speed >= 16) {
    met = 6.8;
  }

  return met * weight * durationHours;
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff7ed),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffffedd5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xffc2410c),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xff9a3412),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalRouteMap extends StatelessWidget {
  const _RentalRouteMap({required this.history});
  final RentalHistory history;

  @override
  Widget build(BuildContext context) {
    final points = history.locationPoints
        .map((e) => latlong.LatLng(e.latitude, e.longitude))
        .toList();

    if (points.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xfff1f5f3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xffe3ebe7),
            style: BorderStyle.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: const Color(0xff23866f).withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Peta rute tidak tersedia\n(Total jarak: ${history.totalDistanceKilometers.toStringAsFixed(1)} km)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xff23866f).withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: MapWidget(
          latitude: points.last.latitude,
          longitude: points.last.longitude,
          routePoints: points,
          routeColor: Colors.blue, // Perintah: Rute warna biru
          latestLocationLabel: 'Titik Finish',
          routeLabel: 'Rute Perjalanan',
        ),
      ),
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffe8f7f2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.pedal_bike,
            color: Color(0xff23866f),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                history.bike?.code ?? 'SMART BIKE',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff073f3a),
                ),
              ),
              Text(
                dateFormat.format(history.startedAt),
                style: const TextStyle(
                  color: Color(0xff8a9590),
                  fontWeight: FontWeight.w500,
                ),
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
  const _RideMetricsGrid({required this.history, this.userWeight});
  final RentalHistory history;
  final num? userWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe3ebe7)),
      ),
      child: Row(
        children: [
          _MetricItem(
            label: 'Jarak',
            value: history.totalDistanceKilometers.toStringAsFixed(1),
            unit: 'km',
            icon: Icons.map_rounded,
            color: Colors.blue,
          ),
          Container(width: 1, height: 36, color: const Color(0xffe3ebe7)),
          _MetricItem(
            label: 'Durasi',
            value: history.durationMinutes.toString(),
            unit: 'min',
            icon: Icons.timer_rounded,
            color: Colors.orange,
          ),
          Container(width: 1, height: 36, color: const Color(0xffe3ebe7)),
          _MetricItem(
            label: 'Avg. Kecepatan',
            value: history.averageSpeed.toStringAsFixed(1),
            unit: 'km/j',
            icon: Icons.speed_rounded,
            color: Colors.purple,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.7), size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff073f3a),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff8a9590),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff8a9590),
              fontWeight: FontWeight.w500,
            ),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff073f3a),
            ),
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
            time: history.endedAt != null
                ? timeFormat.format(history.endedAt!)
                : '-',
            label: 'Selesai Berkendara',
            isStart: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.label,
    required this.isStart,
  });
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
            color: isStart
                ? AppColors.primaryLight.withValues(alpha: 0.1)
                : const Color(0xfff1f5f9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isStart ? AppColors.primaryLight : const Color(0xffcbd5e1),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isStart
                    ? AppColors.primaryLight
                    : const Color(0xffcbd5e1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff073f3a),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xff8a9590)),
              ),
            ],
          ),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xff073f3a),
            ),
          ),
          const Divider(height: 32),
          _InfoRow(
            label: 'Biaya Jarak',
            value: currency.format(history.distanceCost),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Biaya Idle',
            value: currency.format(history.idleCost),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Total Biaya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff073f3a),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.format(history.totalCost),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryLight,
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xff8a9590)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
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
    final color = isCompleted
        ? const Color(0xff23866f)
        : const Color(0xffd14148);
    final bgColor = isCompleted
        ? const Color(0xffe8f7f2)
        : const Color(0xffffecef);

    return GestureDetector(
      onTap:
          status.toLowerCase() == 'active' ||
              status.toLowerCase() == 'idle_warning' ||
              status.toLowerCase() == 'idle_billing'
          ? () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          : null,
      child: Container(
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
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.history, this.userWeight});

  final RentalHistory history;
  final num? userWeight;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMM yyyy', 'id_ID');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Highlight Perjalanan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xff073f3a),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Desain premium siap dibagikan!',
              style: TextStyle(color: Color(0xff8a9590)),
            ),
            const SizedBox(height: 32),
            // THE CARD (Vertical Poster Style)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff269276).withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // BACKGROUND: Mesh Gradient Effect (Compact)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    // DECORATION: Abstract Waves
                    Positioned.fill(
                      child: CustomPaint(painter: _MeshWavePainter()),
                    ),
                    // DECORATION: Dot Pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(painter: _DotPatternPainter()),
                      ),
                    ),
                    // DECORATION: Large Bike Icon
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Opacity(
                        opacity: 0.08,
                        child: const Icon(
                          Icons.pedal_bike,
                          size: 220,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // CONTENT
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMART BIKE',
                                    style: TextStyle(
                                      color: Color(0xff4ade80),
                                      letterSpacing: 2,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'HIGHLIGHT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.eco_rounded,
                                color: Color(0xff4ade80),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CompactStat(
                                label: 'JARAK',
                                value: history.totalDistanceKilometers
                                    .toStringAsFixed(1),
                                unit: 'km',
                              ),
                              _CompactStat(
                                label: 'DURASI',
                                value: history.durationMinutes.toString(),
                                unit: 'min',
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dateFormat.format(history.startedAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      history.bike?.code ?? 'UNIT-01',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  final summary =
                      '''
🚲 *Ringkasan Smart Bike* 🚲

Sepeda: ${history.bike?.code ?? 'N/A'}
Jarak: ${history.totalDistanceKilometers.toStringAsFixed(2)} km
Durasi: ${history.durationString}
Total Biaya: Rp${NumberFormat('#,###', 'id_ID').format(history.totalCost)}

#SmartBike #EcoFriendly #Cycling
''';
                  Clipboard.setData(ClipboardData(text: summary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ringkasan perjalanan disalin ke clipboard!',
                      ),
                      backgroundColor: Color(0xff269276),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                label: const Text(
                  'Salin Ringkasan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff269276),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff64748b),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label, value, unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _MeshWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = ui.Path();
    for (int i = 0; i < 5; i++) {
      path.moveTo(0, size.height * (0.2 + i * 0.15));
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.1 + i * 0.15),
        size.width,
        size.height * (0.3 + i * 0.15),
      );
    }
    canvas.drawPath(path, paint);

    // Abstract circles
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      100,
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.02),
    );
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 150, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
