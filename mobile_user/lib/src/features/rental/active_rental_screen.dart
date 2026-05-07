import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/rental.dart';
import '../../services/api_client.dart';
import 'map_widget.dart';

class ActiveRentalScreen extends StatefulWidget {
  const ActiveRentalScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<ActiveRentalScreen> createState() => _ActiveRentalScreenState();
}

class _ActiveRentalScreenState extends State<ActiveRentalScreen> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  Timer? _refreshTimer;
  Timer? _durationTimer;
  final List<LatLng> _routePoints = [];
  Rental? _rental;
  int? _routeRentalId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isFinishing = false;
  String? _error;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRental();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadRental(silent: true),
    );
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRental({bool silent = false}) async {
    if (_isRefreshing) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final detail = await widget.api.activeRentalDetail();
      if (!mounted) {
        return;
      }
      final rental = detail == null ? null : Rental.fromJson(detail);

      setState(() {
        _rental = rental;
        _syncRoutePoints(rental);
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat rental aktif.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _finishRental() async {
    final rental = _rental;
    if (rental == null) {
      return;
    }

    setState(() => _isFinishing = true);
    try {
      final finished = await widget.api.finishRental(rental.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sewa selesai. Total ${_currency.format(finished.totalCost)}.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Gagal menyelesaikan sewa.');
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncRoutePoints(Rental? rental) {
    if (rental == null) {
      _routeRentalId = null;
      _routePoints.clear();
      return;
    }

    if (_routeRentalId != rental.id) {
      _routeRentalId = rental.id;
      _routePoints.clear();
    }

    final latitude = rental.bike?.latitude;
    final longitude = rental.bike?.longitude;
    if (latitude == null || longitude == null) {
      return;
    }

    final nextPoint = LatLng(latitude, longitude);
    if (_routePoints.isEmpty ||
        calculateDistance(_routePoints.last, nextPoint) >= 1) {
      _routePoints.add(nextPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = _rental;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Aktif'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadRental(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRental,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (rental == null)
                    const _NoActiveRental()
                  else
                    _RentalDetail(
                      rental: rental,
                      currency: _currency,
                      duration: _durationFor(rental),
                      routePoints: List.unmodifiable(_routePoints),
                      isFinishing: _isFinishing,
                      onFinish: _finishRental,
                    ),
                ],
              ),
            ),
    );
  }

  Duration _durationFor(Rental rental) {
    final startedAt = rental.startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }

    final duration = _now.difference(startedAt);
    return duration.isNegative ? Duration.zero : duration;
  }
}

class _RentalDetail extends StatelessWidget {
  const _RentalDetail({
    required this.rental,
    required this.currency,
    required this.duration,
    required this.routePoints,
    required this.isFinishing,
    required this.onFinish,
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
    final latitude = bike?.latitude;
    final longitude = bike?.longitude;

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
        ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xccffffff),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              style.label,
              style: TextStyle(
                color: style.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
            color: emphasized ? const Color(0xff0f766e) : const Color(0xff475467),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f3),
        border: Border.all(color: const Color(0xfffda29b)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _NoActiveRental extends StatelessWidget {
  const _NoActiveRental();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, size: 40),
          SizedBox(height: 12),
          Text('Belum ada rental aktif.'),
        ],
      ),
    );
  }
}
