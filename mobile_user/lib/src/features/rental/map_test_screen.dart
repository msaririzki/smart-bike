import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/api_client.dart';
import 'map_widget.dart';
import 'rolling_number.dart';
import 'routing_service.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  static const _fallbackPosition = LatLng(-8.5830, 116.1163);

  static final _popularSpots = [
    const PopularSpot(name: 'Taman Kota Mataram', position: LatLng(-8.5810, 116.1150), icon: Icons.park, category: 'Taman'),
    const PopularSpot(name: 'Pantai Loang Baloq', position: LatLng(-8.5780, 116.0980), icon: Icons.beach_access, category: 'Pantai'),
    const PopularSpot(name: 'Mall Epicentrum', position: LatLng(-8.5890, 116.1230), icon: Icons.shopping_bag, category: 'Mall'),
    const PopularSpot(name: 'Masjid Islamic Center', position: LatLng(-8.5760, 116.1120), icon: Icons.mosque, category: 'Tempat Ibadah'),
    const PopularSpot(name: 'Universitas Bumigora', position: LatLng(-8.5776, 116.1264), icon: Icons.school, category: 'Kampus'),
    const PopularSpot(name: 'Taman Mayura', position: LatLng(-8.5868, 116.1331), icon: Icons.temple_hindu, category: 'Taman'),
    const PopularSpot(name: 'Taman Sangkareang', position: LatLng(-8.5830, 116.1118), icon: Icons.nature_people, category: 'Taman'),
  ];

  // Bike position from backend
  LatLng _bikePosition = _fallbackPosition;
  List<LatLng> _pathHistory = [];
  double _bikeSpeed = 0;
  double _totalDistance = 0;
  String _rentalStatus = '';
  int? _rentalId;
  DateTime? _lastGpsUpdate;
  String _bikeName = '';

  // User's own location
  LatLng? _userPosition;
  StreamSubscription<Position>? _userPosStream;

  // Polling
  Timer? _pollTimer;
  bool _isPolling = false;

  // UI state
  MapType _mapType = MapType.standard;
  String _locationName = 'Mendeteksi lokasi...';
  Duration _elapsed = Duration.zero;
  Timer? _clockTimer;
  DateTime? _rentalStartedAt;

  // Navigation
  List<LatLng> _navigationRoute = [];
  bool _isLoadingRoute = false;
  PopularSpot? _activeSpot;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _userPosStream?.cancel();
    super.dispose();
  }

  // ── User GPS (blue dot only) ──

  Future<void> _initUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      if (mounted) setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));

      _userPosStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        if (mounted) setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
      });
    } catch (_) {}
  }

  // ── Backend Polling ──

  void _startPolling() {
    _fetchRentalData();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchRentalData());
  }

  Future<void> _fetchRentalData() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final rental = await widget.api.activeRental();
      if (!mounted) return;

      if (rental != null) {
        final bike = rental.bike;
        final hasCoords = bike?.latitude != null && bike?.longitude != null;

        setState(() {
          _rentalId = rental.id;
          _rentalStatus = rental.status;
          _bikeSpeed = rental.currentSpeedKmh;
          _totalDistance = rental.totalDistanceMeters;
          _bikeName = bike != null ? '${bike.code} - ${bike.name}' : '';
          if (hasCoords) {
            _bikePosition = LatLng(bike!.latitude!, bike.longitude!);
          }
          if (rental.startedAt != null && _rentalStartedAt == null) {
            _rentalStartedAt = rental.startedAt;
            _startClock();
          }
        });

        if (hasCoords) _updateLocationName(_bikePosition);

        // Fetch path history
        if (_rentalId != null) {
          try {
            final points = await widget.api.rentalLocationPoints(_rentalId!);
            if (mounted) {
              setState(() => _pathHistory = points.map((p) => p.latLng).toList());
            }
          } catch (_) {}
        }
      } else {
        if (mounted) {
          setState(() {
            _rentalId = null;
            _rentalStatus = '';
            _bikeName = '';
            _bikeSpeed = 0;
            _totalDistance = 0;
            _pathHistory = [];
          });
        }
      }
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _rentalStartedAt == null) return;
      setState(() => _elapsed = DateTime.now().difference(_rentalStartedAt!));
    });
  }

  Future<void> _updateLocationName(LatLng point) async {
    final name = await RoutingService.reverseGeocode(point);
    if (mounted) setState(() => _locationName = name);
  }

  // ── Navigation ──

  Future<void> _onSpotTap(PopularSpot spot) async {
    setState(() { _isLoadingRoute = true; _activeSpot = spot; });

    final result = await RoutingService.getRoute(origin: _bikePosition, destination: spot.position);
    if (!mounted) return;

    if (result != null) {
      setState(() { _navigationRoute = result.points; _isLoadingRoute = false; });
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => _SpotRouteDetail(
          spot: spot,
          distanceMeters: result.distanceMeters,
          durationSeconds: result.durationSeconds,
          onNavigate: () { Navigator.pop(context); setState(() => _isNavigating = true); },
          onClearRoute: () { setState(() { _navigationRoute = []; _activeSpot = null; }); Navigator.pop(context); },
        ),
      );
    } else {
      setState(() => _isLoadingRoute = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mendapatkan rute. Cek koneksi internet.')));
    }
  }

  void _onRoutePointTap(int index, LatLng point) {
    final dist = totalRouteDistance(_pathHistory.isEmpty ? [_bikePosition] : _pathHistory.sublist(0, min(index + 1, _pathHistory.length)));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _RoutePointDetail(index: index, point: point, distanceFromStart: dist, isCurrentPosition: false),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final hasRental = _rentalId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNavigating && _activeSpot != null
            ? 'Menuju ${_activeSpot!.name}'
            : hasRental ? 'Rental Aktif' : 'Live Map'),
        actions: [
          if (hasRental)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatusChip(status: _rentalStatus),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _isPolling ? null : _fetchRentalData,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MapTypeDropdown(value: _mapType, onChanged: (t) => setState(() => _mapType = t)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: MapWidget(
                    latitude: _bikePosition.latitude,
                    longitude: _bikePosition.longitude,
                    routePoints: _pathHistory.isEmpty ? [_bikePosition] : _pathHistory,
                    pathHistory: _pathHistory,
                    accuracyRadius: 15,
                    mapType: _mapType,
                    popularSpots: _popularSpots,
                    navigationRoute: _navigationRoute,
                    userLatitude: _userPosition?.latitude,
                    userLongitude: _userPosition?.longitude,
                    onRoutePointTap: _onRoutePointTap,
                    onSpotTap: _onSpotTap,
                    lastUpdateTime: _lastGpsUpdate,
                  ),
                ),
              ),
              if (!hasRental)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff7ed),
                    border: Border.all(color: const Color(0xfffbbf24)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xfff59e0b)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Belum ada rental aktif. Mulai sewa sepeda dari Home.', style: TextStyle(fontSize: 12, color: Color(0xff92400e)))),
                    ],
                  ),
                ),
              _InfoPanel(
                locationName: _locationName,
                distance: _totalDistance,
                speed: _bikeSpeed,
                elapsed: _elapsed,
                activeSpot: _activeSpot,
                isNavigating: _isNavigating,
                bikeName: _bikeName,
                hasRental: hasRental,
              ),
              _BottomBar(
                isNavigating: _isNavigating,
                hasNavRoute: _navigationRoute.isNotEmpty,
                onClearNav: () => setState(() { _navigationRoute = []; _activeSpot = null; _isNavigating = false; }),
              ),
            ],
          ),
          if (_isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Mencari rute terbaik...'),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Small Widgets ──

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg;
    switch (status) {
      case 'active': bg = const Color(0xffd1fae5); fg = const Color(0xff065f46); break;
      case 'idle_warning': bg = const Color(0xfffef3c7); fg = const Color(0xff92400e); break;
      case 'idle_billing': bg = const Color(0xfffee2e2); fg = const Color(0xff991b1b); break;
      default: bg = const Color(0xfff3f4f6); fg = const Color(0xff374151);
    }
    return Chip(
      label: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MapTypeDropdown extends StatelessWidget {
  const _MapTypeDropdown({required this.value, required this.onChanged});
  final MapType value;
  final ValueChanged<MapType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xffd0d5dd)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<MapType>(
        value: value, isExpanded: true, underline: const SizedBox.shrink(),
        icon: const Icon(Icons.layers, color: Color(0xff0f766e)), borderRadius: BorderRadius.circular(10),
        items: MapType.values.map((type) => DropdownMenuItem(value: type, child: Row(children: [
          Icon(_iconFor(type), size: 18, color: const Color(0xff0f766e)), const SizedBox(width: 10), Text(type.label),
        ]))).toList(),
        onChanged: (t) { if (t != null) onChanged(t); },
      ),
    );
  }

  IconData _iconFor(MapType t) => switch (t) { MapType.standard => Icons.map_outlined, MapType.satellite => Icons.satellite_alt, MapType.hybrid => Icons.layers };
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.locationName, required this.distance, required this.speed, required this.elapsed, this.activeSpot, this.isNavigating = false, this.bikeName = '', this.hasRental = false});
  final String locationName;
  final double distance;
  final double speed;
  final Duration elapsed;
  final PopularSpot? activeSpot;
  final bool isNavigating;
  final String bikeName;
  final bool hasRental;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xfff0fdfa), border: Border.all(color: const Color(0xff99f6e4)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Color(0xff0f766e)),
            const SizedBox(width: 6),
            Expanded(child: Text(locationName.isEmpty ? 'Memuat lokasi...' : locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
          ]),
          if (bikeName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.pedal_bike, size: 14, color: Color(0xff0f766e)),
              const SizedBox(width: 6),
              Text(bikeName, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xff0f766e), fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xffd1fae5), borderRadius: BorderRadius.circular(4)),
                child: const Text('Data dari perangkat sepeda', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff065f46))),
              ),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _InfoItem(icon: Icons.straighten, label: 'Jarak', value: distance >= 1000 ? '${(distance / 1000).toStringAsFixed(2)} km' : '${distance.toStringAsFixed(0)} m')),
            Expanded(child: _InfoItemRolling(icon: Icons.speed, label: 'Kecepatan', value: speed.toStringAsFixed(1), suffix: 'km/h')),
            Expanded(child: _InfoItem(icon: Icons.timer_outlined, label: 'Durasi', value: _fmt(elapsed))),
          ]),
          if (activeSpot != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xffede9fe), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(activeSpot!.icon, size: 16, color: const Color(0xff7c3aed)),
                const SizedBox(width: 8),
                Expanded(child: Text(isNavigating ? 'Menuju ${activeSpot!.name}' : 'Rute ke ${activeSpot!.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff7c3aed)))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours; final m = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: const Color(0xff0f766e)),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xff667085))),
      const SizedBox(height: 2),
      Text(value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

class _InfoItemRolling extends StatelessWidget {
  const _InfoItemRolling({required this.icon, required this.label, required this.value, this.suffix = ''});
  final IconData icon; final String label; final String value; final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: const Color(0xff0f766e)),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xff667085))),
      const SizedBox(height: 2),
      RollingNumber(value: value, suffix: suffix, textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isNavigating, required this.hasNavRoute, required this.onClearNav});
  final bool isNavigating; final bool hasNavRoute; final VoidCallback onClearNav;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        if (hasNavRoute) ...[
          Expanded(child: FilledButton.icon(
            onPressed: onClearNav,
            icon: const Icon(Icons.close),
            label: Text(isNavigating ? 'Batal Navigasi' : 'Hapus Rute'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xffdc2626), padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
        ] else
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: const Color(0xfff0fdfa), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xff99f6e4))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.touch_app, size: 16, color: Color(0xff0f766e)),
              SizedBox(width: 8),
              Text('Ketuk tempat populer di peta untuk navigasi', style: TextStyle(fontSize: 12, color: Color(0xff0f766e), fontWeight: FontWeight.w500)),
            ]),
          )),
      ]),
    );
  }
}

// ── Bottom Sheet Widgets ──

class _RoutePointDetail extends StatelessWidget {
  const _RoutePointDetail({required this.index, required this.point, required this.distanceFromStart, required this.isCurrentPosition});
  final int index; final LatLng point; final double distanceFromStart; final bool isCurrentPosition;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffd0d5dd), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: isCurrentPosition ? const Color(0xff0f766e) : const Color(0xfff0fdfa), shape: BoxShape.circle, border: Border.all(color: const Color(0xff0d9488), width: 2)),
            child: Icon(isCurrentPosition ? Icons.my_location : Icons.circle, size: 18, color: isCurrentPosition ? Colors.white : const Color(0xff0d9488))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Titik Perjalanan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(isCurrentPosition ? 'Posisi saat ini' : 'Sudah dilewati', style: TextStyle(color: isCurrentPosition ? const Color(0xff0f766e) : const Color(0xff667085), fontWeight: FontWeight.w500)),
          ])),
        ]),
        const SizedBox(height: 16), const Divider(), const SizedBox(height: 12),
        FutureBuilder<String>(future: RoutingService.reverseGeocode(point), builder: (ctx, snap) => _DetailRow(icon: Icons.location_on, label: 'Lokasi', value: snap.data ?? 'Memuat...')),
        const SizedBox(height: 10),
        _DetailRow(icon: Icons.straighten, label: 'Jarak dari start', value: distanceFromStart >= 1000 ? '${(distanceFromStart / 1000).toStringAsFixed(2)} km' : '${distanceFromStart.toStringAsFixed(0)} m'),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _SpotRouteDetail extends StatelessWidget {
  const _SpotRouteDetail({required this.spot, required this.distanceMeters, required this.durationSeconds, required this.onNavigate, required this.onClearRoute});
  final PopularSpot spot; final double distanceMeters; final double durationSeconds; final VoidCallback onNavigate; final VoidCallback onClearRoute;

  @override
  Widget build(BuildContext context) {
    final minutes = (durationSeconds / 60).ceil();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xffd0d5dd), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xff8b5cf6), shape: BoxShape.circle), child: Icon(spot.icon, color: Colors.white, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(spot.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xffede9fe), borderRadius: BorderRadius.circular(6)),
              child: Text(spot.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff7c3aed)))),
          ])),
        ]),
        const SizedBox(height: 16), const Divider(), const SizedBox(height: 12),
        _DetailRow(icon: Icons.route, label: 'Jarak tempuh', value: distanceMeters >= 1000 ? '${(distanceMeters / 1000).toStringAsFixed(2)} km' : '${distanceMeters.toStringAsFixed(0)} m'),
        const SizedBox(height: 10),
        _DetailRow(icon: Icons.access_time, label: 'Estimasi waktu', value: '$minutes menit bersepeda'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: onNavigate, icon: const Icon(Icons.navigation), label: const Text('Mulai Navigasi'), style: FilledButton.styleFrom(backgroundColor: const Color(0xff8b5cf6), padding: const EdgeInsets.symmetric(vertical: 14)))),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(onPressed: onClearRoute, icon: const Icon(Icons.close), label: const Text('Batal'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16))),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xff667085)),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: Color(0xff667085), fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]);
  }
}