import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bike.dart';
import '../../models/rental.dart';
import '../../services/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.api, required this.onLogout, super.key});

  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  List<Bike> _bikes = const [];
  Rental? _activeRental;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.bikes(),
        widget.api.activeRental(),
      ]);
      setState(() {
        _bikes = results[0] as List<Bike>;
        _activeRental = results[1] as Rental?;
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Gagal memuat data. Pastikan backend aktif.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startRental(Bike bike) async {
    setState(() => _isBusy = true);
    try {
      final rental = await widget.api.startRental(bike.id);
      setState(() => _activeRental = rental);
      await _load();
      _showMessage('Rental dimulai untuk ${bike.code}.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _finishRental() async {
    final rental = _activeRental;
    if (rental == null) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final finished = await widget.api.finishRental(rental.id);
      setState(() => _activeRental = null);
      await _load();
      _showMessage(
        'Sewa selesai. Total ${_currency.format(finished.totalCost)}.',
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Bike'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  _ActiveRentalPanel(
                    rental: _activeRental,
                    currency: _currency,
                    isBusy: _isBusy,
                    onFinish: _finishRental,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sepeda Tersedia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_bikes.isEmpty)
                    const _EmptyState()
                  else
                    for (final bike in _bikes)
                      _BikeTile(
                        bike: bike,
                        isBusy: _isBusy || _activeRental != null,
                        onStart: () => _startRental(bike),
                      ),
                ],
              ),
            ),
    );
  }
}

class _ActiveRentalPanel extends StatelessWidget {
  const _ActiveRentalPanel({
    required this.rental,
    required this.currency,
    required this.isBusy,
    required this.onFinish,
  });

  final Rental? rental;
  final NumberFormat currency;
  final bool isBusy;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final rental = this.rental;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rental == null ? Colors.white : const Color(0xffecfdf5),
        border: Border.all(
          color: rental == null
              ? const Color(0xffd0d5dd)
              : const Color(0xff99f6e4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: rental == null
          ? const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belum ada rental aktif. Pilih sepeda untuk mulai.',
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rental Aktif - ${rental.bike?.code ?? 'Bike'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _Metric(label: 'Status', value: rental.status),
                    _Metric(
                      label: 'Jarak',
                      value:
                          '${rental.totalDistanceMeters.toStringAsFixed(1)} m',
                    ),
                    _Metric(
                      label: 'Biaya Jarak',
                      value: currency.format(rental.distanceCost),
                    ),
                    _Metric(
                      label: 'Biaya Idle',
                      value: currency.format(rental.idleCost),
                    ),
                    _Metric(
                      label: 'Total',
                      value: currency.format(rental.totalCost),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isBusy ? null : onFinish,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Akhiri Sewa'),
                ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({
    required this.bike,
    required this.isBusy,
    required this.onStart,
  });

  final Bike bike;
  final bool isBusy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bike.isAvailable
              ? const Color(0xffccfbf1)
              : const Color(0xfffee2e2),
          child: Icon(
            Icons.pedal_bike,
            color: bike.isAvailable
                ? const Color(0xff0f766e)
                : const Color(0xffb42318),
          ),
        ),
        title: Text('${bike.code} - ${bike.name}'),
        subtitle: Text(
          'Status: ${bike.status} | ${bike.isOnline ? 'online' : 'offline'}'
          '${bike.batteryPercent == null ? '' : ' | baterai ${bike.batteryPercent}%'}',
        ),
        trailing: FilledButton(
          onPressed: bike.isAvailable && !isBusy ? onStart : null,
          child: const Text('Sewa'),
        ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(child: Text('Belum ada data sepeda.')),
    );
  }
}
