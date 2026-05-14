import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/bike.dart';
import '../../services/api_client.dart';
import 'map_widget.dart';
import 'rolling_number.dart';
import 'routing_service.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key, required this.api, this.focusBike});
  final ApiClient api;

  /// Optional bike to focus on when the map opens (from "Lacak" button).
  final Bike? focusBike;

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  // Default map center (Mataram): only used when no data at all.
  static const _defaultCenter = LatLng(-8.5830, 116.1163);

  static final _popularSpots = [
    const PopularSpot(name: 'Taman Kota Mataram', position: LatLng(-8.5810, 116.1150), icon: Icons.park, category: 'Taman'),
    const PopularSpot(name: 'Pantai Loang Baloq', position: LatLng(-8.5780, 116.0980), icon: Icons.beach_access, category: 'Pantai'),
    const PopularSpot(name: 'Mall Epicentrum', position: LatLng(-8.5890, 116.1230), icon: Icons.shopping_bag, category: 'Mall'),
    const PopularSpot(name: 'Masjid Islamic Center', position: LatLng(-8.5760, 116.1120), icon: Icons.mosque, category: 'Tempat Ibadah'),
    const PopularSpot(name: 'Universitas Bumigora', position: LatLng(-8.5776, 116.1264), icon: Icons.school, category: 'Kampus'),
    const PopularSpot(name: 'Taman Mayura', position: LatLng(-8.5868, 116.1331), icon: Icons.temple_hindu, category: 'Taman'),
    const PopularSpot(name: 'Taman Sangkareang', position: LatLng(-8.5830, 116.1118), icon: Icons.nature_people, category: 'Taman'),
  ];

  // Bike position from backend: null when no GPS data yet.
  LatLng? _bikePosition;
  List<LatLng> _pathHistory = [];
  double _bikeSpeed = 0;
  double _totalDistance = 0;
  String _rentalStatus = '';
  int? _rentalId;
  String _bikeName = '';
  bool _hasBikeCoords = false;

  // User's own location (blue dot)
  LatLng? _userPosition;
  StreamSubscription<Position>? _userPosStream;

  // Polling
  Timer? _pollTimer;
  bool _isPolling = false;

  // UI state
  MapType _mapType = MapType.standard;
  String _locationName = 'Menunggu data sepeda...';
  Duration _elapsed = Duration.zero;
  Timer? _clockTimer;
  DateTime? _rentalStartedAt;

  @override
  void initState() {
    super.initState();
    // If a specific bike was passed (from "Lacak" button), focus on it
    final fb = widget.focusBike;
    if (fb != null && fb.latitude != null && fb.longitude != null) {
      _bikePosition = LatLng(fb.latitude!, fb.longitude!);
      _hasBikeCoords = true;
      _bikeName = '${fb.code} - ${fb.name}';
      _locationName = 'Lokasi ${fb.code}';
    }
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

  // User GPS: blue dot only.

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

  // Backend polling.

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
          _hasBikeCoords = hasCoords;
          if (hasCoords) {
            _bikePosition = LatLng(bike!.latitude!, bike.longitude!);
          }
          if (rental.startedAt != null && _rentalStartedAt == null) {
            _rentalStartedAt = rental.startedAt;
            _startClock();
          }
        });

        if (hasCoords) _updateLocationName(_bikePosition!);

        // Fetch path history from backend (recorded by mobile_bike)
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
          // Preserve focusBike data when there's no active rental
          final fb = widget.focusBike;
          final hasFocus = fb != null && fb.latitude != null && fb.longitude != null;
          setState(() {
            _rentalId = null;
            _rentalStatus = '';
            _bikeSpeed = 0;
            _totalDistance = 0;
            _pathHistory = [];
            _rentalStartedAt = null;
            _elapsed = Duration.zero;
            if (hasFocus) {
              // Keep showing the focused bike's location
              _bikePosition = LatLng(fb.latitude!, fb.longitude!);
              _hasBikeCoords = true;
              _bikeName = '${fb.code} - ${fb.name}';
              _locationName = 'Lokasi ${fb.code}';
            } else {
              _bikeName = '';
              _bikePosition = null;
              _hasBikeCoords = false;
              _locationName = 'Menunggu data sepeda...';
            }
          });
          _clockTimer?.cancel();
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

  // Spot info: view only, no navigation.

  void _onSpotTap(PopularSpot spot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _SpotInfoSheet(spot: spot, bikePosition: _bikePosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRental = _rentalId != null;
    // Map center: bike position > user position > default
    final mapCenter = _bikePosition ?? _userPosition ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasRental ? 'Lokasi Sepeda' : 'Live Map'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _MapTypeDropdown(value: _mapType, onChanged: (t) => setState(() => _mapType = t)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: MapWidget(
                latitude: mapCenter.latitude,
                longitude: mapCenter.longitude,
                routePoints: _pathHistory,
                pathHistory: _pathHistory,
                accuracyRadius: _hasBikeCoords ? 15 : 0,
                mapType: _mapType,
                popularSpots: _popularSpots,
                userLatitude: _userPosition?.latitude,
                userLongitude: _userPosition?.longitude,
                onSpotTap: _onSpotTap,
                // Only show bike marker when we have real GPS data from backend
                bikeLabel: _hasBikeCoords ? _bikeName : null,
              ),
            ),
          ),
          // Status messages
          if (!hasRental)
            _StatusBanner(
              icon: Icons.info_outline,
              text: 'Belum ada rental aktif. Mulai sewa sepeda dari Home.',
              bgColor: const Color(0xfffff7ed),
              borderColor: const Color(0xfffbbf24),
              iconColor: const Color(0xfff59e0b),
              textColor: const Color(0xff92400e),
            ),
          if (hasRental && !_hasBikeCoords)
            _StatusBanner(
              icon: Icons.gps_off,
              text: 'Menunggu data GPS dari perangkat sepeda...',
              bgColor: const Color(0xfff0f9ff),
              borderColor: const Color(0xff93c5fd),
              iconColor: const Color(0xff3b82f6),
              textColor: const Color(0xff1e40af),
            ),
          _InfoPanel(
            locationName: _locationName,
            distance: _totalDistance,
            speed: _bikeSpeed,
            elapsed: _elapsed,
            bikeName: _bikeName,
            hasRental: hasRental,
            hasBikeCoords: _hasBikeCoords,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xfff0fdfa), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xff99f6e4))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xff0f766e)),
                const SizedBox(width: 8),
                Text(
                  hasRental
                      ? 'Data lokasi dikirim oleh perangkat sepeda (mobile_bike)'
                      : 'Ketuk tempat populer di peta untuk info jarak',
                  style: const TextStyle(fontSize: 11, color: Color(0xff0f766e), fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Small widgets.

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
  const _InfoPanel({required this.locationName, required this.distance, required this.speed, required this.elapsed, this.bikeName = '', this.hasRental = false, this.hasBikeCoords = false});
  final String locationName;
  final double distance;
  final double speed;
  final Duration elapsed;
  final String bikeName;
  final bool hasRental;
  final bool hasBikeCoords;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xfff0fdfa), border: Border.all(color: const Color(0xff99f6e4)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            Icon(hasBikeCoords ? Icons.location_on : Icons.location_off, size: 16, color: Color(hasBikeCoords ? 0xff0f766e : 0xff9ca3af)),
            const SizedBox(width: 6),
            Expanded(child: Text(locationName.isEmpty ? 'Memuat lokasi...' : locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
          ]),
          if (bikeName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.pedal_bike, size: 14, color: Color(0xff0f766e)),
              const SizedBox(width: 6),
              Flexible(child: Text(bikeName, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xff0f766e), fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xffd1fae5), borderRadius: BorderRadius.circular(4)),
                child: const Text('Perangkat sepeda', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff065f46))),
              ),
            ]),
          ],
          if (hasRental) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _InfoItem(icon: Icons.straighten, label: 'Jarak', value: distance >= 1000 ? '${(distance / 1000).toStringAsFixed(2)} km' : '${distance.toStringAsFixed(0)} m')),
              Expanded(child: _InfoItemRolling(icon: Icons.speed, label: 'Kecepatan', value: speed.toStringAsFixed(1), suffix: 'km/h')),
              Expanded(child: _InfoItem(icon: Icons.timer_outlined, label: 'Durasi', value: _fmt(elapsed))),
            ]),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text, required this.bgColor, required this.borderColor, required this.iconColor, required this.textColor});
  final IconData icon; final String text; final Color bgColor; final Color borderColor; final Color iconColor; final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: textColor))),
      ]),
    );
  }
}

/// Info sheet when tapping a popular spot; view only, shows distance from bike.
class _SpotInfoSheet extends StatelessWidget {
  const _SpotInfoSheet({required this.spot, this.bikePosition});
  final PopularSpot spot;
  final LatLng? bikePosition;

  @override
  Widget build(BuildContext context) {
    final dist = bikePosition != null ? calculateDistance(bikePosition!, spot.position) : null;

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
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xffede9fe), borderRadius: BorderRadius.circular(6)),
              child: Text(spot.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff7c3aed)))),
          ])),
        ]),
        const SizedBox(height: 16), const Divider(), const SizedBox(height: 12),
        _DetailRow(icon: Icons.location_on, label: 'Koordinat', value: '${spot.position.latitude.toStringAsFixed(4)}, ${spot.position.longitude.toStringAsFixed(4)}'),
        if (dist != null) ...[
          const SizedBox(height: 10),
          _DetailRow(icon: Icons.straighten, label: 'Jarak dari sepeda', value: dist >= 1000 ? '${(dist / 1000).toStringAsFixed(2)} km' : '${dist.toStringAsFixed(0)} m'),
        ] else ...[
          const SizedBox(height: 10),
          const _DetailRow(icon: Icons.info_outline, label: 'Info', value: 'Belum ada data lokasi sepeda'),
        ],
        const SizedBox(height: 16),
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
