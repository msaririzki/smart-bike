import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/notification_model.dart';
import '../../theme/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/api_client.dart';
import '../../services/session_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bantuan_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({
    required this.notification,
    this.isPinned = false,
    super.key,
  });

  final NotificationData notification;
  final bool isPinned;

  String _formatDateTime(DateTime dt) {
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(localDt.year, localDt.month, localDt.day);

    final timeStr = DateFormat('HH:mm').format(localDt);

    if (date == today) {
      return 'Hari ini, $timeStr';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Kemarin, $timeStr';
    }

    return '${DateFormat('dd MMM yyyy').format(localDt)}, $timeStr';
  }

  DateTime? _parseLocalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Widget _buildSewaDetail(BuildContext context) {
    final d = notification.data ?? {};
    final bool isCompleted = d['rental_status'] == 'completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Ringkasan Perjalanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xff111827),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('ID Sepeda', d['bike_code'] ?? 'Tidak diketahui'),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Waktu Mulai',
          _parseLocalDateTime(d['started_at']) != null
              ? _formatDateTime(_parseLocalDateTime(d['started_at'])!)
              : '-',
        ),

        if (isCompleted) ...[
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Waktu Selesai',
            _parseLocalDateTime(d['ended_at']) != null
                ? _formatDateTime(_parseLocalDateTime(d['ended_at'])!)
                : '-',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Durasi',
            d['duration_minutes'] != null
                ? '${d['duration_minutes']} menit'
                : '-',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Jarak',
            d['distance_meters'] != null
                ? '${((d['distance_meters'] as num) / 1000).toStringAsFixed(1)} km'
                : '-',
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Titik Sampai', d['end_location'] ?? '-'),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Biaya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xff111827),
                ),
              ),
              Text(
                d['total_cost'] != null
                    ? 'Rp ${NumberFormat('#,###', 'id_ID').format(d['total_cost'])}'
                    : 'Rp 0',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _RentalMapWidget(rentalId: d['rental_id']),
        ] else ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Titik Keberangkatan', d['start_location'] ?? '-'),
          const SizedBox(height: 12),
          _buildSummaryRow('Status Baterai / Kondisi', d['battery'] ?? 'Baik'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfffef3c7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xfffde68a)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 18,
                      color: Color(0xffd97706),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Catatan Keamanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff92400e),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  d['safety_notes'] ??
                      'Pastikan standar sepeda sudah dinaikkan. Selalu parkirkan kembali sepeda di shelter resmi terdekat agar terhindar dari denda tambahan.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff92400e),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.support_agent_rounded,
            color: Color(0xff4b5563),
          ),
          title: const Text(
            'Bantuan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff374151),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xff9ca3af),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BantuanScreen(bikeId: d['bike_code']?.toString()),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Selesai',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPengumumanDetail() {
    final isPromo = notification.type == 'promosi';

    // Fallback for older notifications that don't have start/end times
    final startDt = notification.startTime ?? notification.createdAt;
    final endDt =
        notification.endTime ??
        notification.createdAt.add(const Duration(hours: 5));

    final startTimeFormat = DateFormat(
      'EEEE, dd MMM yyyy\n\'Pukul\' HH.mm \'WITA\'',
      'id_ID',
    ).format(startDt.toLocal());
    final endTimeFormat = DateFormat(
      'EEEE, dd MMM yyyy\n\'Pukul\' HH.mm \'WITA\'',
      'id_ID',
    ).format(endDt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isPromo)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 20,
                color: Color(0xff6b7280),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waktu Mulai',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startTimeFormat,
                    style: const TextStyle(
                      color: Color(0xff6b7280),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        if (!isPromo) const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 20,
              color: Color(0xff6b7280),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPromo ? 'Waktu Promosi Berakhir' : 'Waktu Selesai',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endTimeFormat,
                  style: const TextStyle(
                    color: Color(0xff6b7280),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xfff3f4f6), thickness: 1.5),
        const SizedBox(height: 24),
        Text(
          notification.message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xff374151),
          ),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: '${notification.title}\n\n${notification.message}',
              ),
            );
          },
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('Bagikan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff4b5563),
            side: const BorderSide(color: Color(0xffd1d5db)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xff6b7280), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff374151),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSewa = notification.type == 'sewa';
    final isPromo = notification.type == 'promosi';

    // Updated colors to match design
    final Color bgColor = isSewa
        ? AppColors.primaryLight.withValues(alpha: 0.15)
        : (isPromo ? const Color(0xfffce7f3) : const Color(0xfffffbeb));
    final Color iconColor = isSewa
        ? AppColors.primaryLight
        : (isPromo ? const Color(0xffec4899) : const Color(0xfff59e0b));
    final IconData icon = isSewa
        ? Icons.directions_bike_rounded
        : (isPromo ? Icons.discount_rounded : Icons.campaign_rounded);

    final String appBarTitle = isSewa
        ? 'Detail Sewa'
        : (isPromo ? 'Promo Spesial' : 'Pengumuman');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            elevation: 3,
            offset: const Offset(0, 40),
            onSelected: (value) async {
              if (value == 'unread') {
                try {
                  await NotificationService().markAsUnread(notification.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ditandai belum dibaca')),
                    );
                    Navigator.pop(context, 'refresh');
                  }
                } catch (_) {}
              } else if (value == 'delete') {
                try {
                  await NotificationService().deleteNotification(
                    notification.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifikasi dihapus')),
                    );
                    Navigator.pop(context, 'refresh');
                  }
                } catch (_) {}
              } else if (value == 'copy') {
                await Clipboard.setData(
                  ClipboardData(text: notification.message),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks pengumuman disalin')),
                  );
                }
              } else if (value == 'copy_promo') {
                final promoCode =
                    notification.data?['promo_code'] ?? notification.message;
                await Clipboard.setData(ClipboardData(text: promoCode));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode promo disalin')),
                  );
                }
              } else if (value == 'pin' || value == 'unpin') {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fitur $value segera hadir!')),
                );
              }
            },
            itemBuilder: (context) {
              if (isSewa) {
                final isCompleted =
                    notification.data?['rental_status'] == 'completed';
                return [
                  const PopupMenuItem(
                    value: 'unread',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, size: 20),
                        SizedBox(width: 12),
                        Text('Tandai Belum Dibaca'),
                      ],
                    ),
                  ),
                  if (isCompleted) ...[
                    const PopupMenuItem(
                      value: 'invoice',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long, size: 20),
                          SizedBox(width: 12),
                          Text('Download Invoice / Bukti Bayar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rent_again',
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 20),
                          SizedBox(width: 12),
                          Text('Sewa Sepeda Ini Lagi'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Hapus dari Riwayat',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ];
              } else if (isPromo) {
                return [
                  const PopupMenuItem(
                    value: 'unread',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, size: 20),
                        SizedBox(width: 12),
                        Text('Tandai Belum Dibaca'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: isPinned ? 'unpin' : 'pin',
                    child: Row(
                      children: [
                        Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(isPinned ? 'Lepas Sematan' : 'Sematkan di Atas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy_promo',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 20),
                        SizedBox(width: 12),
                        Text('Salin Kode Promo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Hapus Promosi',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
              } else {
                return [
                  const PopupMenuItem(
                    value: 'unread',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, size: 20),
                        SizedBox(width: 12),
                        Text('Tandai Belum Dibaca'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: isPinned ? 'unpin' : 'pin',
                    child: Row(
                      children: [
                        Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(isPinned ? 'Lepas Sematan' : 'Sematkan di Atas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remind',
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty, size: 20),
                        SizedBox(width: 12),
                        Text('Ingatkan Saya Nanti'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 20),
                        SizedBox(width: 12),
                        Text('Salin Teks Pengumuman'),
                      ],
                    ),
                  ),
                ];
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              notification.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xff111827),
              ),
            ),
            const SizedBox(height: 8),
            if (isSewa)
              const Text(
                'Terima kasih telah menggunakan FlowBike.',
                style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _formatDateTime(notification.createdAt),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff6b7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xfff3f4f6), thickness: 1.5),
            const SizedBox(height: 24),

            if (isSewa) _buildSewaDetail(context) else _buildPengumumanDetail(),
          ],
        ),
      ),
    );
  }
}

class _RentalMapWidget extends StatefulWidget {
  final dynamic rentalId;
  const _RentalMapWidget({this.rentalId});

  @override
  State<_RentalMapWidget> createState() => _RentalMapWidgetState();
}

class _RentalMapWidgetState extends State<_RentalMapWidget> {
  List<LatLng> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    if (widget.rentalId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final token = await SessionStore().token;
      if (token == null) return;
      final response = await http.get(
        Uri.parse(
          '${ApiClient.baseUrl}/rentals/${widget.rentalId}/location-points',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        final points = data
            .map(
              (p) => LatLng(
                double.parse(p['latitude'].toString()),
                double.parse(p['longitude'].toString()),
              ),
            )
            .toList();
        if (mounted) {
          setState(() {
            _points = points;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xfff3f4f6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_points.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xfff3f4f6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, color: Color(0xff9ca3af), size: 48),
              SizedBox(height: 8),
              Text(
                'Tidak ada rute yang tersimpan',
                style: TextStyle(color: Color(0xff9ca3af)),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate bounds for map
    final bounds = LatLngBounds.fromPoints(_points);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(24),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.flowbike.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _points,
                color: AppColors.primaryLight,
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _points.first,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              Marker(
                point: _points.last,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
