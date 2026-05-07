import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'map_widget.dart';
import 'routing_service.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  // Fallback jika GPS gagal (Mataram city center)
  static const _fallbackPosition = LatLng(-8.5830, 116.1163);

  static final _popularSpots = [
    const PopularSpot(
      name: 'Taman Kota Mataram',
      position: LatLng(-8.5810, 116.1150),
      icon: Icons.park,
      category: 'Taman',
    ),
    const PopularSpot(
      name: 'Pantai Loang Baloq',
      position: LatLng(-8.5780, 116.0980),
      icon: Icons.beach_access,
      category: 'Pantai',
    ),
    const PopularSpot(
      name: 'Mall Epicentrum',
      position: LatLng(-8.5890, 116.1230),
      icon: Icons.shopping_bag,
      category: 'Mall',
    ),
    const PopularSpot(
      name: 'Masjid Islamic Center',
      position: LatLng(-8.5760, 116.1120),
      icon: Icons.mosque,
      category: 'Tempat Ibadah',
    ),
    const PopularSpot(
      name: 'Universitas Bumigora',
      position: LatLng(-8.5776, 116.1264),
      icon: Icons.school,
      category: 'Kampus',
    ),
    const PopularSpot(
      name: 'Taman Mayura',
      position: LatLng(-8.5868, 116.1331),
      icon: Icons.temple_hindu,
      category: 'Taman',
    ),
    const PopularSpot(
      name: 'Taman Sangkareang',
      position: LatLng(-8.5830, 116.1118),
      icon: Icons.nature_people,
      category: 'Taman',
    ),
  ];

  LatLng _userPosition = _fallbackPosition;
  LatLng _pickupPoint = _fallbackPosition;
  List<LatLng> _trail = [_fallbackPosition];
  StreamSubscription<Position>? _posStream;
  Timer? _clockTimer;
  bool _isTracking = false;
  double _speed = 0;
  MapType _mapType = MapType.standard;
  Duration _elapsed = Duration.zero;
  List<LatLng> _navigationRoute = [];
  bool _isLoadingRoute = false;
  PopularSpot? _activeSpot;
  String _locationName = 'Mendeteksi lokasi...';
  bool _isNavigating = false;
  bool _gpsLoading = true;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'GPS tidak aktif. Menggunakan lokasi default.';
          _gpsLoading = false;
        });
        _updateLocationName(_userPosition);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Izin lokasi ditolak. Menggunakan lokasi default.';
            _gpsLoading = false;
          });
          _updateLocationName(_userPosition);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Izin lokasi ditolak permanen. Buka pengaturan.';
          _gpsLoading = false;
        });
        _updateLocationName(_userPosition);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final gpsPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = gpsPoint;
        _pickupPoint = gpsPoint;
        _trail = [gpsPoint];
        _gpsLoading = false;
        _gpsError = null;
      });
      _updateLocationName(gpsPoint);
    } catch (e) {
      setState(() {
        _gpsError = 'Gagal mendapatkan lokasi GPS.';
        _gpsLoading = false;
      });
      _updateLocationName(_userPosition);
    }
  }

  Future<void> _updateLocationName(LatLng point) async {
    final name = await RoutingService.reverseGeocode(point);
    if (mounted) setState(() => _locationName = name);
  }

  void _startTracking() {
    _posStream?.cancel();
    _clockTimer?.cancel();

    setState(() {
      _trail = [_userPosition];
      _speed = 0;
      _elapsed = Duration.zero;
      _isTracking = true;
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });

    const locSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _posStream = Geolocator.getPositionStream(locationSettings: locSettings)
        .listen((pos) {
      if (!mounted) return;
      final newPt = LatLng(pos.latitude, pos.longitude);
      final prev = _userPosition;
      final dist = calculateDistance(prev, newPt);
      if (dist < 1.5) return;
      final spd = pos.speed >= 0 ? pos.speed * 3.6 : (dist / 3 * 3.6);
      setState(() {
        _userPosition = newPt;
        _trail.add(newPt);
        _speed = spd;
      });
      _updateLocationName(newPt);
    });
  }

  void _stopTracking() {
    _posStream?.cancel();
    _clockTimer?.cancel();
    setState(() => _isTracking = false);
  }

  void _resetTracking() {
    _posStream?.cancel();
    _clockTimer?.cancel();
    setState(() {
      _trail = [_userPosition];
      _isTracking = false;
      _speed = 0;
      _elapsed = Duration.zero;
      _navigationRoute = [];
      _activeSpot = null;
      _isNavigating = false;
    });
    _updateLocationName(_userPosition);
  }

  void _onRoutePointTap(int index, LatLng point) {
    final distToHere = totalRouteDistance(_trail.sublist(0, index + 1));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RoutePointDetail(
        index: index,
        point: point,
        distanceFromStart: distToHere,
        isCurrentPosition: index == _trail.length - 1,
      ),
    );
  }

  Future<void> _onSpotTap(PopularSpot spot) async {
    final bikePos = _userPosition;

    setState(() {
      _isLoadingRoute = true;
      _activeSpot = spot;
    });

    final result = await RoutingService.getRoute(
      origin: bikePos,
      destination: spot.position,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _navigationRoute = result.points;
        _isLoadingRoute = false;
      });

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _SpotRouteDetail(
          spot: spot,
          distanceMeters: result.distanceMeters,
          durationSeconds: result.durationSeconds,
          onNavigate: () {
            Navigator.pop(context);
            _startLiveNavigation(result.points, spot);
          },
          onClearRoute: () {
            setState(() {
              _navigationRoute = [];
              _activeSpot = null;
            });
            Navigator.pop(context);
          },
        ),
      );
    } else {
      setState(() => _isLoadingRoute = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan rute. Cek koneksi internet.'),
        ),
      );
    }
  }

  void _startLiveNavigation(List<LatLng> routePoints, PopularSpot spot) {
    setState(() {
      _navigationRoute = routePoints;
      _isNavigating = true;
      _activeSpot = spot;
    });
    if (!_isTracking) _startTracking();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _userPosition;
    final distance = totalRouteDistance(_trail);

    return Scaffold(
      appBar: AppBar(
        title: _isNavigating && _activeSpot != null
            ? Text('Menuju ${_activeSpot!.name}')
            : Text(_gpsLoading ? 'Mendeteksi GPS...' : (_isTracking ? 'Live Tracking Aktif' : 'Live Map')),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh GPS',
            onPressed: _gpsLoading ? null : () {
              setState(() => _gpsLoading = true);
              _initGps();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MapTypeDropdown(
                  value: _mapType,
                  onChanged: (type) => setState(() => _mapType = type),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: MapWidget(
                    latitude: cur.latitude,
                    longitude: cur.longitude,
                    routePoints: List.from(_trail),
                    accuracyRadius: 15,
                    mapType: _mapType,
                    pickupPoint: _pickupPoint,
                    popularSpots: _popularSpots,
                    navigationRoute: _navigationRoute,
                    onRoutePointTap: _onRoutePointTap,
                    onSpotTap: _onSpotTap,
                  ),
                ),
              ),
              if (_gpsError != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff7ed),
                    border: Border.all(color: const Color(0xfffbbf24)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, size: 16, color: Color(0xfff59e0b)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsError!,
                          style: const TextStyle(fontSize: 12, color: Color(0xff92400e)),
                        ),
                      ),
                    ],
                  ),
                ),
              _InfoPanel(
                locationName: _locationName,
                distance: distance,
                speed: _speed,
                elapsed: _elapsed,
                activeSpot: _activeSpot,
                isNavigating: _isNavigating,
              ),
              _LiveControlBar(
                isTracking: _isTracking,
                isNavigating: _isNavigating,
                onStart: _startTracking,
                onStop: _stopTracking,
                onReset: _resetTracking,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mencari rute terbaik...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<MapType>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.layers, color: Color(0xff0f766e)),
        borderRadius: BorderRadius.circular(10),
        items: MapType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(_iconFor(type), size: 18, color: const Color(0xff0f766e)),
                const SizedBox(width: 10),
                Text(type.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (type) {
          if (type != null) onChanged(type);
        },
      ),
    );
  }

  IconData _iconFor(MapType type) {
    return switch (type) {
      MapType.standard => Icons.map_outlined,
      MapType.satellite => Icons.satellite_alt,
      MapType.hybrid => Icons.layers,
    };
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.locationName,
    required this.distance,
    required this.speed,
    required this.elapsed,
    this.activeSpot,
    this.isNavigating = false,
  });

  final String locationName;
  final double distance;
  final double speed;
  final Duration elapsed;
  final PopularSpot? activeSpot;
  final bool isNavigating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdfa),
        border: Border.all(color: const Color(0xff99f6e4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xff0f766e)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationName.isEmpty ? 'Memuat lokasi...' : locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.straighten,
                  label: 'Jarak',
                  value: distance >= 1000
                      ? '${(distance / 1000).toStringAsFixed(2)} km'
                      : '${distance.toStringAsFixed(0)} m',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.speed,
                  label: 'Kecepatan',
                  value: '${speed.toStringAsFixed(1)} km/h',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  value: _formatDuration(elapsed),
                ),
              ),
            ],
          ),
          if (activeSpot != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffede9fe),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(activeSpot!.icon, size: 16, color: const Color(0xff7c3aed)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isNavigating
                          ? 'Menuju ${activeSpot!.name}'
                          : 'Rute ke ${activeSpot!.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff7c3aed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xff0f766e)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xff667085),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LiveControlBar extends StatelessWidget {
  const _LiveControlBar({
    required this.isTracking,
    required this.isNavigating,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  final bool isTracking;
  final bool isNavigating;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isTracking ? onStop : onStart,
              icon: Icon(isTracking ? Icons.stop : Icons.gps_fixed),
              label: Text(isTracking ? 'Stop Tracking' : 'Mulai Tracking'),
              style: FilledButton.styleFrom(
                backgroundColor: isTracking
                    ? const Color(0xffdc2626)
                    : const Color(0xff0f766e),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onReset,
            icon: const Icon(Icons.replay),
            label: Text(isNavigating ? 'Batal' : 'Reset'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePointDetail extends StatelessWidget {
  const _RoutePointDetail({
    required this.index,
    required this.point,
    required this.distanceFromStart,
    required this.isCurrentPosition,
  });

  final int index;
  final LatLng point;
  final double distanceFromStart;
  final bool isCurrentPosition;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd0d5dd),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrentPosition
                      ? const Color(0xff0f766e)
                      : const Color(0xfff0fdfa),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff0d9488), width: 2),
                ),
                child: Icon(
                  isCurrentPosition ? Icons.my_location : Icons.circle,
                  size: 18,
                  color: isCurrentPosition
                      ? Colors.white
                      : const Color(0xff0d9488),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Titik Perjalanan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCurrentPosition ? 'Posisi saat ini' : 'Sudah dilewati',
                      style: TextStyle(
                        color: isCurrentPosition
                            ? const Color(0xff0f766e)
                            : const Color(0xff667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: RoutingService.reverseGeocode(point),
            builder: (context, snapshot) {
              return _DetailRow(
                icon: Icons.location_on,
                label: 'Lokasi',
                value: snapshot.data ?? 'Memuat...',
              );
            },
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.straighten,
            label: 'Jarak dari start',
            value: distanceFromStart >= 1000
                ? '${(distanceFromStart / 1000).toStringAsFixed(2)} km'
                : '${distanceFromStart.toStringAsFixed(0)} m',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: isCurrentPosition ? 'Posisi Terkini' : 'Terlewati',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SpotRouteDetail extends StatelessWidget {
  const _SpotRouteDetail({
    required this.spot,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.onNavigate,
    required this.onClearRoute,
  });

  final PopularSpot spot;
  final double distanceMeters;
  final double durationSeconds;
  final VoidCallback onNavigate;
  final VoidCallback onClearRoute;

  @override
  Widget build(BuildContext context) {
    final minutes = (durationSeconds / 60).ceil();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd0d5dd),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xff8b5cf6),
                  shape: BoxShape.circle,
                ),
                child: Icon(spot.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffede9fe),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        spot.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff7c3aed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.route,
            label: 'Jarak tempuh',
            value: distanceMeters >= 1000
                ? '${(distanceMeters / 1000).toStringAsFixed(2)} km'
                : '${distanceMeters.toStringAsFixed(0)} m',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Estimasi waktu',
            value: '$minutes menit bersepeda',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Mulai Navigasi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff8b5cf6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: onClearRoute,
                icon: const Icon(Icons.close),
                label: const Text('Batal'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff667085)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xff667085),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}