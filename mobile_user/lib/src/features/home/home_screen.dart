import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bike.dart';
import '../../models/rental.dart';
import '../../services/api_client.dart';
import '../rental/active_rental_screen.dart';

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
      await _openActiveRental();
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

  Future<void> _openActiveRental() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ActiveRentalScreen(api: widget.api)),
    );

    if (mounted) {
      await _load();
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
      backgroundColor: const Color(0xfff7fbf8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                    children: [
                      _HomeHeader(
                        onRefresh: _isLoading ? null : _load,
                        onLogout: widget.onLogout,
                      ),
                      const SizedBox(height: 18),
                      if (_error != null) _ErrorBanner(message: _error!),
                      _ActiveRentalCard(
                        rental: _activeRental,
                        currency: _currency,
                        isBusy: _isBusy,
                        onFinish: _finishRental,
                        onOpen: _openActiveRental,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Sepeda Tersedia',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color(0xff073f3a),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih sepeda dan mulai perjalananmu',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xff8a9590),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_bikes.isEmpty)
                        const _EmptyState()
                      else
                        for (final bike in _bikes) ...[
                          _BikeCard(
                            bike: bike,
                            isBusy: _isBusy || _activeRental != null,
                            onStart: () => _startRental(bike),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
                const _BottomNavigationMock(),
              ],
            ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onRefresh, required this.onLogout});

  final VoidCallback? onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Bike',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xff063f3a),
                  fontWeight: FontWeight.w900,
                  fontSize: 34,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Sewa sepeda mudah & cepat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xff8a9590),
                ),
              ),
            ],
          ),
        ),
        _RoundAction(
          tooltip: 'Logout',
          icon: Icons.notifications_none_rounded,
          badge: true,
          onPressed: onLogout,
        ),
        const SizedBox(width: 12),
        _RoundAction(
          tooltip: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badge = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: const Color(0x1f0f766e),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: const Color(0xff23866f), size: 24),
                if (badge)
                  const Positioned(
                    right: 12,
                    top: 11,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0xff23866f),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveRentalCard extends StatelessWidget {
  const _ActiveRentalCard({
    required this.rental,
    required this.currency,
    required this.isBusy,
    required this.onFinish,
    required this.onOpen,
  });

  final Rental? rental;
  final NumberFormat currency;
  final bool isBusy;
  final VoidCallback onFinish;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final rental = this.rental;

    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff269276),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29299276),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -56,
            top: 26,
            child: CircleAvatar(radius: 98, backgroundColor: Color(0x4dffffff)),
          ),
          const Positioned(right: -22, bottom: 26, child: _RentalImageSlot()),
          const Positioned(
            right: 194,
            bottom: 4,
            child: Icon(Icons.eco_outlined, size: 70, color: Color(0x1fffffff)),
          ),
          if (rental == null)
            const _InactiveRentalContent()
          else
            _ActiveRentalContent(
              rental: rental,
              currency: currency,
              isBusy: isBusy,
              onFinish: onFinish,
              onOpen: onOpen,
            ),
        ],
      ),
    );
  }
}

class _InactiveRentalContent extends StatelessWidget {
  const _InactiveRentalContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Aktif',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        SizedBox(height: 8),
        Text(
          'Belum Ada',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        _StatusPill(label: 'pilih sepeda'),
        Spacer(),
        SizedBox(
          width: 260,
          child: Text(
            'Mulai sewa dari daftar sepeda di bawah.',
            style: TextStyle(color: Color(0xe6ffffff), fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _ActiveRentalContent extends StatelessWidget {
  const _ActiveRentalContent({
    required this.rental,
    required this.currency,
    required this.isBusy,
    required this.onFinish,
    required this.onOpen,
  });

  final Rental rental;
  final NumberFormat currency;
  final bool isBusy;
  final VoidCallback onFinish;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isBusy ? null : onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rental Aktif',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            rental.bike?.code ?? 'BIKE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          _StatusPill(label: rental.status.replaceAll('_', ' ')),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 88,
                child: _CardStat(
                  label: 'Jarak',
                  value: '${rental.totalDistanceMeters.toStringAsFixed(1)} m',
                ),
              ),
              SizedBox(
                width: 106,
                child: _CardStat(
                  label: 'Biaya Jarak',
                  value: currency.format(rental.distanceCost),
                ),
              ),
              SizedBox(
                width: 90,
                child: _CardStat(
                  label: 'Biaya Idle',
                  value: currency.format(rental.idleCost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(width: 220, height: 1, color: const Color(0x26ffffff)),
          const SizedBox(height: 7),
          _CardStat(
            label: 'Total',
            value: currency.format(rental.totalCost),
            large: true,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 190,
            height: 44,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onFinish,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff18846e),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(Icons.stop_circle_outlined, size: 21),
              label: const Text(
                'Akhiri Sewa',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 3, backgroundColor: Color(0xff23866f)),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff23866f),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xe6ffffff),
            fontSize: large ? 12 : 11,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: large ? 21 : 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RentalImageSlot extends StatelessWidget {
  const _RentalImageSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0x33ffffff),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33ffffff)),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xccffffff), size: 42),
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  const _BikeCard({
    required this.bike,
    required this.isBusy,
    required this.onStart,
  });

  final Bike bike;
  final bool isBusy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final available = bike.isAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe3ebe7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0f000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: available
                ? const Color(0xffe8f7f2)
                : const Color(0xffffecef),
            child: Icon(
              Icons.pedal_bike,
              color: available
                  ? const Color(0xff23866f)
                  : const Color(0xffd14148),
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike.code,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xff073f3a),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bike.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xff535d59),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 4,
                      backgroundColor: Color(0xff23866f),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${bike.status}  |  ${bike.isOnline ? 'online' : 'offline'}  |  baterai ${bike.batteryPercent ?? 0}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xff606a66),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            height: 38,
            child: FilledButton(
              onPressed: available && !isBusy ? onStart : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xff269276),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xff269276),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sewa',
                maxLines: 1,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationMock extends StatelessWidget {
  const _BottomNavigationMock();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 12,
      child: SizedBox(
        height: 68,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1a000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BottomNavItem(
                      icon: Icons.home_rounded,
                      label: 'Beranda',
                      active: true,
                    ),
                    _BottomNavItem(
                      icon: Icons.location_on_outlined,
                      label: 'Peta',
                    ),
                    SizedBox(width: 62),
                    _BottomNavItem(
                      icon: Icons.history_rounded,
                      label: 'Riwayat',
                    ),
                    _BottomNavItem(icon: Icons.person_outline, label: 'Profil'),
                  ],
                ),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff269276),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4d269276),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xff23866f) : const Color(0xff7f8784);

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
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
