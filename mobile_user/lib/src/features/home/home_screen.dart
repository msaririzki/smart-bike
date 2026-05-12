import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../models/bike.dart';
import '../../models/rental.dart';
import '../../models/rental_history.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../history/history_screen.dart';
import '../rental/active_rental_screen.dart';
import '../rental/map_test_screen.dart';
import '../rental/qr_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.api, required this.onLogout, super.key});

  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _dashboardKey = GlobalKey<_DashboardPageState>();
  final _historyKey = GlobalKey<HistoryScreenState>();

  Future<void> _refreshCurrentTab() async {
    if (_selectedIndex == 0) {
      await _dashboardKey.currentState?.load();
    }
    if (_selectedIndex == 3) {
      await _historyKey.currentState?.loadHistory();
    }
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const _NotificationRow(
                  icon: Icons.lock_open_rounded,
                  title: 'Scan QR untuk sewa',
                  subtitle:
                      'Mulai sewa dengan memindai QR dari perangkat sepeda.',
                ),
                const SizedBox(height: 12),
                const _NotificationRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat sudah tersimpan',
                  subtitle: 'Detail biaya dan durasi bisa dicek kapan saja.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRefresh = _selectedIndex == 0 || _selectedIndex == 3;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 253, 255, 254),
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/flowbike3.svg',
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Flow',
                        style: TextStyle(color: Color(0xFF349665)),
                      ),
                      TextSpan(
                        text: 'Bike',
                        style: TextStyle(color: Color(0xFF133C36)),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Ride Smooth. Track Smart.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: _showNotifications,
            icon: Badge(
              smallSize: 8,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          if (canRefresh)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshCurrentTab,
              icon: const Icon(Icons.refresh_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardPage(
            key: _dashboardKey,
            api: widget.api,
            onOpenScanner: _openQrScanner,
          ),
          const _ComingSoonPage(
            icon: Icons.map_outlined,
            title: 'Peta sepeda',
            message: 'Tampilan peta akan aktif bersama fitur scan to rent.',
          ),
          const _ComingSoonPage(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan to rent',
            message: 'Gunakan tombol Scan untuk memindai QR dari sepeda.',
          ),
          HistoryScreen(
            key: _historyKey,
            api: widget.api,
            showScaffold: false,
            bottomPadding: 92,
          ),
          _ProfilePage(onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MapTestScreen(api: widget.api)),
            );
          } else if (index == 2) {
            _openQrScanner();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Future<void> _openQrScanner() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => QrScanScreen(api: widget.api)));
    await _dashboardKey.currentState?.load();
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage({
    required this.api,
    required this.onOpenScanner,
    super.key,
  });

  final ApiClient api;
  final VoidCallback onOpenScanner;

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  List<Bike> _bikes = const [];
  List<RentalHistory> _historyPreview = const [];
  Rental? _activeRental;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.bikes(),
        widget.api.activeRental(),
        widget.api.rentalHistory(page: 1),
      ]);
      final historyPayload = results[2] as Map<String, dynamic>;
      final historyItems = historyPayload['data'] as List<dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _bikes = results[0] as List<Bike>;
        _activeRental = results[1] as Rental?;
        _historyPreview = historyItems
            .take(3)
            .map((item) => RentalHistory.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal memuat data. Pastikan backend aktif.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      await load();
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
      await load();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 92),
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          _GreetingBlock(
            activeRental: _activeRental,
            bikeCount: _bikes.where((bike) => bike.isAvailable).length,
          ),
          const SizedBox(height: 20),
          _ActiveRentalPanel(
            rental: _activeRental,
            currency: _currency,
            isBusy: _isBusy,
            onFinish: _finishRental,
            onOpen: _openActiveRental,
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Riwayat terbaru',
            onTap: () {
              final homeState = context
                  .findAncestorStateOfType<_HomeScreenState>();
              homeState?.setState(() => homeState._selectedIndex = 3);
            },
          ),
          const SizedBox(height: 12),
          _HistoryPreviewList(history: _historyPreview, currency: _currency),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Sepeda tersedia',
            subtitle: 'Untuk mulai sewa, scan QR pada perangkat sepeda.',
          ),
          const SizedBox(height: 12),
          if (_bikes.isEmpty)
            const _EmptyState()
          else
            for (final bike in _bikes) ...[
              _BikeListTile(
                bike: bike,
                isBusy: _isBusy || _activeRental != null,
                onScan: widget.onOpenScanner,
              ),
            ],
        ],
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.activeRental, required this.bikeCount});

  final Rental? activeRental;
  final int bikeCount;

  @override
  Widget build(BuildContext context) {
    final hasActiveRental = activeRental != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasActiveRental ? 'Perjalanan sedang berjalan' : 'Siap bersepeda?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasActiveRental
              ? 'Pantau biaya dan akhiri sewa saat tujuan sudah tercapai.'
              : '$bikeCount sepeda siap digunakan. Scan QR di sepeda untuk mulai.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xff6b7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ActiveRentalPanel extends StatelessWidget {
  const _ActiveRentalPanel({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -240,
            top: 0,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/flowbike4.svg',
                width: 450,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          rental == null
              ? const _NoActiveRental()
              : _ActiveRentalSummary(
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

class _NoActiveRental extends StatelessWidget {
  const _NoActiveRental();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.pedal_bike_outlined,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Belum ada rental aktif',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Scan QR di perangkat sepeda untuk mulai.',
                style: TextStyle(color: Color(0xFFa7c4b8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveRentalSummary extends StatelessWidget {
  const _ActiveRentalSummary({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.bike?.code ?? 'SMART BIKE',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rental.status.replaceAll('_', ' '),
                    style: const TextStyle(color: Color(0xFFa7c4b8)),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: isBusy ? null : onOpen,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFa7c4b8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InlineStats(
          stats: [
            _InlineStatData(
              icon: Icons.straighten_rounded,
              label: 'Jarak',
              value: '${rental.totalDistanceMeters.toStringAsFixed(0)} m',
            ),
            _InlineStatData(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Idle',
              value: currency.format(rental.idleCost),
            ),
            _InlineStatData(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total',
              value: currency.format(rental.totalCost),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onOpen,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Lihat Detail'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primaryDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: isBusy ? null : onFinish,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Akhiri'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineStatData {
  const _InlineStatData({required this.label, required this.value, this.icon});

  final IconData? icon;
  final String label;
  final String value;
}

class _InlineStats extends StatelessWidget {
  const _InlineStats({required this.stats});

  final List<_InlineStatData> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (stats[index].icon != null) ...[
                      Icon(
                        stats[index].icon,
                        size: 14,
                        color: const Color(0xFFa7c4b8),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        stats[index].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  stats[index].label,
                  style: const TextStyle(
                    color: Color(0xFFa7c4b8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (index != stats.length - 1)
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white.withValues(alpha: 0.2),
            ),
        ],
      ],
    );
  }
}

class _HistoryPreviewList extends StatelessWidget {
  const _HistoryPreviewList({required this.history, required this.currency});

  final List<RentalHistory> history;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text(
        'Belum ada perjalanan yang selesai.',
        style: TextStyle(color: Color(0xff6b7280)),
      );
    }

    final dateFormat = DateFormat('d MMM', 'id_ID');

    return Column(
      children: [
        for (final item in history) ...[
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  dateFormat.format(item.startedAt),
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.bike?.code ?? 'SMART BIKE',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.durationString} - ${item.totalDistanceKilometers.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: Color(0xff6b7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currency.format(item.totalCost),
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (item != history.last)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
        ],
      ],
    );
  }
}

class _BikeListTile extends StatelessWidget {
  const _BikeListTile({
    required this.bike,
    required this.isBusy,
    required this.onScan,
  });

  final Bike bike;
  final bool isBusy;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final available = bike.isAvailable;
    final statusColor = available
        ? AppColors.primaryLight
        : const Color(0xffdc2626);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _SoftIcon(
            icon: Icons.pedal_bike_rounded,
            color: available ? AppColors.primaryLight : const Color(0xffdc2626),
            backgroundColor: available
                ? const Color(0xffecfdf5)
                : const Color(0xfffff1f2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${bike.name} - ${bike.isOnline ? 'online' : 'offline'} - baterai ${bike.batteryPercent ?? 0}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xff6b7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            bike.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: available && !isBusy ? onScan : null,
            child: const Text('Scan QR'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.onTap});

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(color: Color(0xff6b7280)),
                ),
              ],
            ],
          ),
        ),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('Lihat semua')),
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    this.color = AppColors.primaryLight,
    this.backgroundColor = const Color(0xffecfdf5),
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftIcon(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: Color(0xff6b7280))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SoftIcon(icon: icon),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff6b7280), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
      children: [
        Text(
          'Akun',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pengaturan profil akan disambungkan setelah data akun lengkap.',
          style: TextStyle(color: Color(0xff6b7280)),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f2),
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
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Belum ada data sepeda.',
        style: TextStyle(color: Color(0xff6b7280)),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  const _CustomBottomNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 80 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Nav bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 68 + bottomPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'Beranda',
                      isSelected: selectedIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.map_outlined,
                      selectedIcon: Icons.map_rounded,
                      label: 'Peta',
                      isSelected: selectedIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    // Spacer for center scan button
                    const Expanded(child: SizedBox()),
                    _NavItem(
                      icon: Icons.history_outlined,
                      selectedIcon: Icons.history_rounded,
                      label: 'Riwayat',
                      isSelected: selectedIndex == 3,
                      onTap: () => onTap(3),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      label: 'Profil',
                      isSelected: selectedIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating Scan button
          Positioned(
            bottom: 18 + bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primaryLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF16a34a,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: selectedIndex == 2 ? 28 : 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selectedIndex == 2
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selectedIndex == 2
                            ? AppColors.primaryLight
                            : const Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryLight : const Color(0xFF6b7280);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
