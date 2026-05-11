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

  String _statusFilter = 'All'; // All, completed, cancelled
  String _periodFilter = 'All'; // All, 7Days, ThisMonth

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadMoreLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadMoreLoading && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final data = await widget.api.rentalHistory(page: 1);
      final rawList = data['data'] as List<dynamic>;
      final history = rawList.map((item) => RentalHistory.fromJson(item as Map<String, dynamic>)).toList();
      
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
          _hasMore = data['current_page'] < data['last_page'];
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

  Future<void> _loadMore() async {
    if (_isLoadMoreLoading || !_hasMore) return;

    setState(() {
      _isLoadMoreLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final data = await widget.api.rentalHistory(page: nextPage);
      final rawList = data['data'] as List<dynamic>;
      final nextHistory = rawList.map((item) => RentalHistory.fromJson(item as Map<String, dynamic>)).toList();

      if (mounted) {
        setState(() {
          _history!.addAll(nextHistory);
          _currentPage = nextPage;
          _hasMore = data['current_page'] < data['last_page'];
          _isLoadMoreLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadMoreLoading = false;
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
          ? const _ShimmerLoadingView()
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 100,
                      child: _ErrorView(message: _error!, onRetry: _loadHistory),
                    ),
                  ),
                )
              : _history == null || _history!.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 100,
                          child: const _EmptyView(),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: _buildFilteredList(),
                    ),
    );
  }

  Widget _buildFilteredList() {
    final filteredHistory = _history!.where((item) {
      // Status Filter
      if (_statusFilter != 'All' && item.status != _statusFilter) {
        return false;
      }

      // Period Filter
      if (_periodFilter != 'All') {
        final now = DateTime.now();
        if (_periodFilter == '7Days') {
          final weekAgo = now.subtract(const Duration(days: 7));
          if (item.startedAt.isBefore(weekAgo)) return false;
        } else if (_periodFilter == 'ThisMonth') {
          if (item.startedAt.month != now.month || item.startedAt.year != now.year) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    if (filteredHistory.isEmpty && _history!.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Column(
            children: [
              _HistorySummaryHeader(history: _history!),
              _buildFilterBar(),
              const Expanded(child: _EmptyView(message: 'Tidak ada data yang cocok dengan filter.')),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: filteredHistory.length + 3, // Summary + Filters + Items + Loading Indicator
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HistorySummaryHeader(history: _history!);
        }
        if (index == 1) {
          return _buildFilterBar();
        }
        
        if (index == filteredHistory.length + 2) {
          return _hasMore 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : const SizedBox(height: 40);
        }

        final itemIndex = index - 2;
        final item = filteredHistory[itemIndex];
        return _HistoryCard(
          history: item,
          onTap: () {
            if (item.status == 'ACTIVE') {
              // Jika aktif, balik ke Home biar user bisa akhiri sewa dengan cepat
              Navigator.pop(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RentalDetailScreen(history: item),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Status',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff64748b)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _statusFilter == 'All',
                onSelected: (s) => setState(() => _statusFilter = 'All'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Selesai',
                selected: _statusFilter == 'completed',
                onSelected: (s) => setState(() => _statusFilter = 'completed'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Dibatalkan',
                selected: _statusFilter == 'cancelled',
                onSelected: (s) => setState(() => _statusFilter = 'cancelled'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Filter Periode',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff64748b)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua Waktu',
                selected: _periodFilter == 'All',
                onSelected: (s) => setState(() => _periodFilter = 'All'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '7 Hari Terakhir',
                selected: _periodFilter == '7Days',
                onSelected: (s) => setState(() => _periodFilter = '7Days'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Bulan Ini',
                selected: _periodFilter == 'ThisMonth',
                onSelected: (s) => setState(() => _periodFilter = 'ThisMonth'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xffe2e8f0)),
      ],
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
            color: const Color(0xff269276).withValues(alpha: 0.2),
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
              _StatItem(label: 'Jarak', value: totalKm.toStringAsFixed(1), unit: 'km'),
              _StatDivider(),
              _StatItem(label: 'Sewa', value: '$totalRentals', unit: 'kali'),
              _StatDivider(),
              _StatItem(label: 'Estimasi', value: co2Text, unit: 'CO2'),
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
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 0.5),
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
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
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
                Container(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            history.bike?.code ?? 'SMART BIKE',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff073f3a),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniStatusBadge(history.status),
                        ],
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

  Widget _buildMiniStatusBadge(String status) {
    Color color;
    String label;
    Color bgColor;

    switch (status) {
      case 'completed':
        color = const Color(0xff23866f);
        bgColor = const Color(0xffe8f7f2);
        label = 'Selesai';
        break;
      case 'cancelled':
        color = const Color(0xffd14148);
        bgColor = const Color(0xffffecef);
        label = 'Batal';
        break;
      default:
        color = const Color(0xff2563eb);
        bgColor = const Color(0xffdbeafe);
        label = 'Aktif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ShimmerLoadingView extends StatelessWidget {
  const _ShimmerLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ),
          const SizedBox(height: 24),
          ...List.generate(5, (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          )),
        ],
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
  const _EmptyView({this.message = 'Belum ada riwayat sewa.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: Color(0xffcbd5e1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Color(0xff94a3b8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xff269276).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xff269276),
      labelStyle: TextStyle(
        color: selected ? const Color(0xff18846e) : const Color(0xff64748b),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xff269276) : const Color(0xffe2e8f0),
          width: 1.5,
        ),
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
                width: 14,
                height: (heightFactor * 60).clamp(10, 60).toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: index == 6 
                      ? [Colors.white, Colors.white.withValues(alpha: 0.8)]
                      : [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  boxShadow: index == 6 ? [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dayName,
                style: TextStyle(
                  color: index == 6 ? Colors.white : Colors.white60,
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

