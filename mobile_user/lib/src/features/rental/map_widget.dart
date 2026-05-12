import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapType {
  standard('Standar'),
  satellite('Satelit'),
  hybrid('Hybrid');

  const MapType(this.label);
  final String label;
}

class PopularSpot {
  const PopularSpot({
    required this.name,
    required this.position,
    required this.icon,
    required this.category,
  });

  final String name;
  final LatLng position;
  final IconData icon;
  final String category;
}

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.routePoints,
    this.accuracyRadius = 0,
    this.mapType = MapType.standard,
    this.pickupPoint,
    this.popularSpots = const [],
    this.navigationRoute = const [],
    this.latestLocationLabel = 'Lokasi sepeda terakhir',
    this.routeLabel = 'Jalur dari perangkat sepeda',
    this.routeColor,
    this.onRoutePointTap,
    this.onSpotTap,
  });

  final double latitude;
  final double longitude;
  final List<LatLng> routePoints;
  final double accuracyRadius;
  final MapType mapType;
  final LatLng? pickupPoint;
  final List<PopularSpot> popularSpots;
  final List<LatLng> navigationRoute;
  final String latestLocationLabel;
  final String routeLabel;
  final Color? routeColor;
  final void Function(int index, LatLng point)? onRoutePointTap;
  final void Function(PopularSpot spot)? onSpotTap;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: pos, initialZoom: 16),
        children: [
          _buildTileLayer(),
          if (widget.mapType == MapType.hybrid) _buildHybridLabelLayer(),
          if (widget.navigationRoute.length >= 2) _buildNavigationRoute(),
          if (widget.routePoints.length >= 2) _buildRouteLayer(),
          if (widget.pickupPoint != null) _buildPickupMarker(),
          if (widget.routePoints.isNotEmpty) _buildStartMarker(),
          if (widget.routePoints.length > 1) _buildRoutePointMarkers(),
          _buildSpotMarkers(),
          if (widget.accuracyRadius > 0) _buildAccuracyCircle(pos),
          _buildBikeMarker(pos),
          _buildSourceLabels(),
        ],
      ),
    );
  }

  Widget _buildSourceLabels() {
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        minimum: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MapSourceChip(
              icon: Icons.pedal_bike,
              label: widget.latestLocationLabel,
            ),
            if (widget.routePoints.length >= 2) ...[
              const SizedBox(height: 6),
              _MapSourceChip(icon: Icons.route, label: widget.routeLabel),
            ],
          ],
        ),
      ),
    );
  }

  TileLayer _buildTileLayer() {
    switch (widget.mapType) {
      case MapType.satellite:
      case MapType.hybrid:
        return TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.mobile_user',
          maxZoom: 19,
        );
      case MapType.standard:
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mobile_user',
        );
    }
  }

  TileLayer _buildHybridLabelLayer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.example.mobile_user',
      maxZoom: 18,
    );
  }

  PolylineLayer _buildNavigationRoute() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.navigationRoute,
          color: const Color(0xff3b82f6),
          strokeWidth: 5,
          borderColor: const Color(0xff1d4ed8).withValues(alpha: 0.4),
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  PolylineLayer _buildRouteLayer() {
    final isSatellite = widget.mapType != MapType.standard;
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.routePoints,
          color: widget.routeColor ??
              (isSatellite ? const Color(0xff38bdf8) : const Color(0xff0d9488)),
          strokeWidth: 4,
          borderColor: (widget.routeColor ??
                  (isSatellite ? const Color(0xff0284c7) : const Color(0xff0f766e)))
              .withValues(alpha: 0.3),
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  MarkerLayer _buildPickupMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.pickupPoint!,
          width: 40,
          height: 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xffef4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 16),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xffef4444),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  MarkerLayer _buildStartMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: widget.routePoints.first,
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xff0f766e), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.flag, color: Color(0xff0f766e), size: 14),
            ),
          ),
        ),
      ],
    );
  }

  MarkerLayer _buildRoutePointMarkers() {
    final markers = <Marker>[];
    for (int i = 1; i < widget.routePoints.length; i++) {
      final point = widget.routePoints[i];
      final isLast = i == widget.routePoints.length - 1;
      if (isLast) continue;
      markers.add(
        Marker(
          point: point,
          width: 14,
          height: 14,
          child: GestureDetector(
            onTap: () => widget.onRoutePointTap?.call(i, point),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff0d9488),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return MarkerLayer(markers: markers);
  }

  MarkerLayer _buildSpotMarkers() {
    return MarkerLayer(
      markers: widget.popularSpots.map((spot) {
        return Marker(
          point: spot.position,
          width: 44,
          height: 52,
          child: GestureDetector(
            onTap: () => widget.onSpotTap?.call(spot),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xff8b5cf6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(spot.icon, color: Colors.white, size: 18),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xff8b5cf6),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  CircleLayer _buildAccuracyCircle(LatLng pos) {
    return CircleLayer(
      circles: [
        CircleMarker(
          point: pos,
          radius: widget.accuracyRadius,
          useRadiusInMeter: true,
          color: const Color(0xff0d9488).withValues(alpha: 0.08),
          borderColor: const Color(0xff0d9488).withValues(alpha: 0.25),
          borderStrokeWidth: 1.5,
        ),
      ],
    );
  }

  MarkerLayer _buildBikeMarker(LatLng pos) {
    return MarkerLayer(
      markers: [
        Marker(
          point: pos,
          width: 56,
          height: 56,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xff0f766e,
                      ).withValues(alpha: _pulseAnimation.value),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xff0f766e),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pedal_bike,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapSourceChip extends StatelessWidget {
  const _MapSourceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1f0f172a)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xff0f766e)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff0f172a),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double calculateDistance(LatLng p1, LatLng p2) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(p2.latitude - p1.latitude);
  final dLng = _toRadians(p2.longitude - p1.longitude);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(p1.latitude)) *
          cos(_toRadians(p2.latitude)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degree) => degree * pi / 180;

double totalRouteDistance(List<LatLng> points) {
  double total = 0;
  for (int i = 1; i < points.length; i++) {
    total += calculateDistance(points[i - 1], points[i]);
  }
  return total;
}
