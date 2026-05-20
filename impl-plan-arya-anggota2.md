# Implementation Plan — Anggota 2: Arya (Live Map)

**Branch:** `feature/live-map`  
**File utama:** `mobile_user/lib/src/features/rental/map_widget.dart`

---

## Strategi: Kerja Mandiri Tanpa Menunggu Riki

Buat `MapWidget` sebagai widget mandiri yang menerima parameter dari luar.
Saat Riki selesai, integrasi hanya 4 baris kode.

---

## File yang Dikerjakan

### 1. MODIFY — `mobile_user/pubspec.yaml`

Tambahkan di bagian `dependencies:`:
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```
Lalu jalankan: `flutter pub get`

---

### 2. NEW — `mobile_user/lib/src/features/rental/map_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.routePoints,
  });

  final double latitude;
  final double longitude;
  final List<LatLng> routePoints;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapWidget old) {
    super.didUpdateWidget(old);
    if (old.latitude != widget.latitude || old.longitude != widget.longitude) {
      _mapController.move(
        LatLng(widget.latitude, widget.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = LatLng(widget.latitude, widget.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: pos, initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mobile_user',
          ),
          if (widget.routePoints.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.routePoints,
                  color: Colors.blue,
                  strokeWidth: 4,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: pos,
                width: 48,
                height: 48,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff0f766e),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pedal_bike, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

### 3. NEW — `mobile_user/lib/src/features/rental/map_test_screen.dart`

Screen sementara untuk test mandiri (hapus setelah integrasi Riki):

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_widget.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});
  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  static const _route = [
    LatLng(-8.5833, 116.1167),
    LatLng(-8.5840, 116.1174),
    LatLng(-8.5848, 116.1182),
    LatLng(-8.5855, 116.1190),
    LatLng(-8.5862, 116.1198),
  ];

  int _idx = 0;
  final List<LatLng> _passed = [LatLng(-8.5833, 116.1167)];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_idx < _route.length - 1) {
        setState(() {
          _idx++;
          _passed.add(_route[_idx]);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _route[_idx];
    return Scaffold(
      appBar: AppBar(title: Text('Test Peta — Titik ${_idx + 1}/${_route.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Expanded(
          child: MapWidget(
            latitude: cur.latitude,
            longitude: cur.longitude,
            routePoints: List.from(_passed),
          ),
        ),
      ),
    );
  }
}
```

---

## Cara Integrasi ke Screen Riki (Setelah Riki Selesai)

Di dalam `active_rental_screen.dart` Riki, Arya tinggal:

1. Import:
```dart
import '../rental/map_widget.dart';
import 'package:latlong2/latlong.dart';
```

2. Tambah state:
```dart
final List<LatLng> _routePoints = [];
```

3. Update saat polling (dalam `Timer.periodic`):
```dart
final lat = rental.bike?.latitude;
final lng = rental.bike?.longitude;
if (lat != null && lng != null) {
  _routePoints.add(LatLng(lat, lng));
}
```

4. Sisipkan widget di body:
```dart
SizedBox(
  height: 250,
  child: MapWidget(
    latitude: rental.bike!.latitude!,
    longitude: rental.bike!.longitude!,
    routePoints: _routePoints,
  ),
),
```

---

## Endpoint yang Dipakai

```
GET /api/rentals/active
→ data.bike.current_latitude   (sudah ada di model Bike sebagai bike.latitude)
→ data.bike.current_longitude  (sudah ada di model Bike sebagai bike.longitude)
```

Model `Bike` sudah mendukung field ini — tidak perlu modifikasi model.

---

## Checklist

- [ ] Tambah dependency di `pubspec.yaml`
- [ ] `flutter pub get` berhasil
- [ ] Buat folder `mobile_user/lib/src/features/rental/`
- [ ] Buat `map_widget.dart`
- [ ] Buat `map_test_screen.dart` untuk test sementara
- [ ] Verifikasi: peta muncul, marker bergerak, polyline tampil
- [ ] Koordinasi dengan Riki untuk integrasi
- [ ] Hapus `map_test_screen.dart` setelah integrasi
- [ ] Push branch `feature/live-map`
