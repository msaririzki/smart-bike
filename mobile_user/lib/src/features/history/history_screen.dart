import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_history.dart';
import '../../services/api_client.dart';
import 'rental_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RentalHistory>? _history;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.api.rentalHistory();
      if (mounted) {
        setState(() {
          _history = data.map((e) => RentalHistory.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan saat memuat riwayat.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7fbf8),
      appBar: AppBar(
        title: const Text(
          'Riwayat Sewa',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff073f3a),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadHistory)
              : _history == null || _history!.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history!.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _HistorySummaryHeader(history: _history!);
                          }
                          final itemIndex = index - 1;
                          final item = _history![itemIndex];
                          return _HistoryCard(
                            history: item,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RentalDetailScreen(history: item),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _HistorySummaryHeader extends StatelessWidget {
  const _HistorySummaryHeader({required this.history});

  final List<RentalHistory> history;

  @override
  Widget build(BuildContext context) {
    final totalKm = history.fold(0.0, (sum, e) => sum + e.totalDistanceKilometers);
    final totalRentals = history.length;
    final totalCo2Gram = totalKm * 120;
    final co2Text = totalCo2Gram >= 1000 ? '${(totalCo2Gram / 1000).toStringAsFixed(1)} kg' : '${totalCo2Gram.toStringAsFixed(0)} g';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff269276), Color(0xff18846e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff269276).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Jarak', value: '${totalKm.toStringAsFixed(1)}', unit: 'km'),
              _StatDivider(),
              _StatItem(label: 'Sewa', value: '$totalRentals', unit: 'kali'),
              _StatDivider(),
              _StatItem(label: 'Saved', value: co2Text, unit: 'CO2'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktivitas 7 Hari',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 55, child: _WeeklyBarChart(history: history)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Badges',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _AchievementBadgesCompact(history: history),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: Colors.white10);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.unit});
  final String label, value, unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(
          unit,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _AchievementBadgesCompact extends StatelessWidget {
  const _AchievementBadgesCompact({required this.history});
  final List<RentalHistory> history;

  @override
  Widget build(BuildContext context) {
    final totalKm = history.fold(0.0, (sum, e) => sum + e.totalDistanceKilometers);
    final totalRentals = history.length;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (totalKm > 10) _CompactBadge(icon: Icons.terrain_rounded, color: Colors.amber),
        if (totalRentals > 5) _CompactBadge(icon: Icons.stars_rounded, color: Colors.orange),
        if (totalKm > 0) _CompactBadge(icon: Icons.directions_bike_rounded, color: Colors.blue),
      ],
    );
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.onTap});

  final RentalHistory history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Hero(
                  tag: 'bike-icon-${history.id}',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0fdf4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pedal_bike_rounded,
                      color: Color(0xff23866f),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.bike?.code ?? 'SMART BIKE',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff073f3a),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dateFormat.format(history.startedAt)} • ${timeFormat.format(history.startedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff94a3b8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(history.totalCost),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff269276),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Color(0xff94a3b8)),
                        const SizedBox(width: 4),
                        Text(
                          history.durationString,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff94a3b8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? const Color(0xff22c55e) : const Color(0xffef4444),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff475569)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Color(0xffcbd5e1)),
          SizedBox(height: 16),
          Text(
            'Belum ada riwayat sewa.',
            style: TextStyle(color: Color(0xff94a3b8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.history});

  final List<RentalHistory> history;

  @override
  Widget build(BuildContext context) {
    // Generate data for last 7 days
    final now = DateTime.now();
    final dayData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayRentals = history.where((e) => 
        e.startedAt.year == date.year && 
        e.startedAt.month == date.month && 
        e.startedAt.day == date.day
      );
      
      // Calculate total duration in minutes for that day
      double totalMinutes = 0;
      for (var r in dayRentals) {
        if (r.endedAt != null) {
          totalMinutes += r.endedAt!.difference(r.startedAt).inMinutes.toDouble();
        }
      }
      return totalMinutes;
    });

    final maxVal = dayData.reduce((a, b) => a > b ? a : b);
    final displayMax = maxVal < 30 ? 30.0 : maxVal; // Min height for scale

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = now.subtract(Duration(days: 6 - index));
          final dayName = DateFormat('E', 'id_ID').format(date).substring(0, 1);
          final heightFactor = dayData[index] / displayMax;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: (heightFactor * 40).clamp(4, 40).toDouble(),
                decoration: BoxDecoration(
                  color: index == 6 ? Colors.white : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayName,
                style: TextStyle(
                  color: index == 6 ? Colors.white : Colors.white70,
                  fontSize: 10,
                  fontWeight: index == 6 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

