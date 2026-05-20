import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'notification_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService();
  List<NotificationData> _notifications = [];
  final Set<int> _pinnedPromoIds = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} tahun yang lalu';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} bulan yang lalu';
    if (diff.inDays > 0) return '${diff.inDays} hari yang lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam yang lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
    return 'Baru saja';
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat notifikasi: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showNotificationDetail(BuildContext context, NotificationData item, bool isSewa, int index) async {
    final isPinned = _pinnedPromoIds.contains(item.id);
    
    if (!item.isRead) {
      // Optimistic update
      setState(() {
        _notifications[index] = NotificationData(
          id: item.id,
          userId: item.userId,
          title: item.title,
          message: item.message,
          type: item.type,
          isRead: true,
          createdAt: item.createdAt,
          startTime: item.startTime,
          endTime: item.endTime,
          data: item.data,
        );
      });
      // Fire and forget
      _service.markAsRead(item.id).catchError((_) {});
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          notification: _notifications[index],
          isPinned: isPinned,
        ),
      ),
    );
    
    if (result == 'refresh') {
      _loadNotifications();
    } else if (result == 'pin') {
      setState(() => _pinnedPromoIds.add(item.id));
    } else if (result == 'unpin') {
      setState(() => _pinnedPromoIds.remove(item.id));
    } else {
      // Force rebuild to ensure red dots reflect correctly
      setState(() {});
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xfff3f4f6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xff9ca3af)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada notifikasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff4b5563)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pemberitahuan aktivitas, sistem, dan promosi akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff6b7280), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationData> list) {
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSewa = item.type == 'sewa';
        final isPromo = item.type == 'promosi';
        
        // Need to find original index to update read state properly
        final originalIndex = _notifications.indexWhere((n) => n.id == item.id);
        
        return InkWell(
          onTap: () => _showNotificationDetail(context, item, isSewa, originalIndex >= 0 ? originalIndex : index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead ? const Color(0xfff3f4f6) : const Color(0xffe5e7eb),
                width: 1,
              ),
              boxShadow: item.isRead 
                  ? [] 
                  : [BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSewa ? AppColors.primaryLight.withValues(alpha: 0.15) : (isPromo ? const Color(0xfffce7f3) : const Color(0xfffffbeb)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSewa ? Icons.directions_bike_rounded : (isPromo ? Icons.discount_rounded : Icons.campaign_rounded),
                    color: isSewa ? AppColors.primaryLight : (isPromo ? const Color(0xffec4899) : const Color(0xfff59e0b)),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                                fontSize: 15,
                                color: item.isRead ? const Color(0xff4b5563) : const Color(0xff111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xffef4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.isRead ? const Color(0xff9ca3af) : const Color(0xff6b7280),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _timeAgo(item.createdAt),
                            style: const TextStyle(
                              color: Color(0xff9ca3af),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              if (isPromo && _pinnedPromoIds.contains(item.id)) ...[
                                const Icon(Icons.push_pin, size: 14, color: Color(0xffec4899)),
                                const SizedBox(width: 8),
                              ],
                              const Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primaryLight),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xfff9fafb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  physics: const NeverScrollableScrollPhysics(),
                  indicator: const BoxDecoration(), // hide default
                  dividerColor: Colors.transparent, // hide line
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  tabs: [
                    _buildTab('Semua', 0),
                    _buildTab('Aktivitas', 1),
                    _buildTab('Sistem', 2),
                    _buildTab('Promosi', 3),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!, style: const TextStyle(color: Colors.red))))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(_notifications),
                    _buildNotificationList(_notifications.where((n) => n.type == 'sewa').toList()),
                    _buildNotificationList(_notifications.where((n) => n.type == 'pengumuman').toList()),
                    _buildNotificationList(_notifications.where((n) => n.type == 'promosi').toList()..sort((a, b) {
                      final aPinned = _pinnedPromoIds.contains(a.id);
                      final bPinned = _pinnedPromoIds.contains(b.id);
                      if (aPinned && !bPinned) return -1;
                      if (!aPinned && bPinned) return 1;
                      return b.createdAt.compareTo(a.createdAt);
                    })),
                  ],
                ),
    );
  }

  Widget _buildTab(String text, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      height: 36,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : const Color(0xffe5e7eb),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xff6b7280),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
