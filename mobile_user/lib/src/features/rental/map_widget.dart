import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/bike.dart';

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
    this.pathHistory = const [],
    this.userLatitude,
    this.userLongitude,
    this.latestLocationLabel = 'Lokasi sepeda terakhir',
    this.routeLabel = 'Jalur dari perangkat sepeda',
    this.routeColor,
    this.onRoutePointTap,
    this.onSpotTap,
    this.bikeLabel,
    this.lastUpdateTime,
    this.availableBikes = const [],
    this.onAvailableBikeTap,
  });

  final double latitude;
  final double longitude;
  final List<LatLng> routePoints;
  final double accuracyRadius;
  final MapType mapType;
  final LatLng? pickupPoint;
  final List<PopularSpot> popularSpots;
  final List<LatLng> navigationRoute;

  /// GPS trail from backend: the path the bike has already traveled.
  final List<LatLng> pathHistory;

  /// User's own location (blue dot).
  final double? userLatitude;
  final double? userLongitude;

  final String latestLocationLabel;
  final String routeLabel;
  final Color? routeColor;
  final void Function(int index, LatLng point)? onRoutePointTap;
  final void Function(PopularSpot spot)? onSpotTap;

  /// Optional label shown near the bike marker.
  final String? bikeLabel;

  /// Timestamp of the last GPS update from the bike device.
  final DateTime? lastUpdateTime;

  /// Available bikes to show as markers on the map.
  final List<Bike> availableBikes;

  /// Callback when an available bike marker is tapped.
  final void Function(Bike bike)? onAvailableBikeTap;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  late final MapController _mapController;

  // Pulse animation for bike marker
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Animated Route Drawing
  AnimationController? _routeAnimController;
  Animation<double>? _routeAnimation;
  List<LatLng> _animatedRoutePoints = [];

  // Marker Bounce
  AnimationController? _bounceController;
  Animation<double>? _bounceAnimation;

  // Smooth bike position interpolation
  AnimationController? _positionAnimController;
  Animation<double>? _positionAnimation;
  LatLng? _previousBikePos;
  LatLng? _targetBikePos;

  // User location pulse
  AnimationController? _userPulseController;
  Animation<double>? _userPulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Bike marker pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Popular spot bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -30.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 15),
    ]).animate(_bounceController!);
    _bounceController!.forward();

    // User location pulse
    if (widget.userLatitude != null) {
      _initUserPulse();
    }

    // Initialize bike position
    _targetBikePos = LatLng(widget.latitude, widget.longitude);
  }

  void _initUserPulse() {
    _userPulseController?.dispose();
    _userPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _userPulseAnimation = Tween<double>(begin: 0.3, end: 0.08).animate(
      CurvedAnimation(parent: _userPulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeAnimController?.dispose();
    _bounceController?.dispose();
    _positionAnimController?.dispose();
    _userPulseController?.dispose();
    super.dispose();
  }

  void _startRouteAnimation(List<LatLng> points) {
    _routeAnimController?.dispose();
    _animatedRoutePoints = points;

    _routeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeAnimController!, curve: Curves.easeInOut),
    );
    _routeAnimController!.forward();
  }

  void _animateBikePosition(LatLng from, LatLng to) {
    _previousBikePos = from;
    _targetBikePos = to;

    _positionAnimController?.dispose();
    _positionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _positionAnimation = CurvedAnimation(
      parent: _positionAnimController!,
      curve: Curves.easeInOutCubic,
    );
    _positionAnimController!.forward();
  }

  LatLng get _interpolatedBikePos {
    if (_positionAnimation == null ||
        _previousBikePos == null ||
        _targetBikePos == null) {
      return LatLng(widget.latitude, widget.longitude);
    }
    final t = _positionAnimation!.value;
    return LatLng(
      _previousBikePos!.latitude +
          (_targetBikePos!.latitude - _previousBikePos!.latitude) * t,
      _previousBikePos!.longitude +
          (_targetBikePos!.longitude - _previousBikePos!.longitude) * t,
    );
  }

  @override
  void didUpdateWidget(MapWidget old) {
    super.didUpdateWidget(old);

    // Smooth bike position transition
    if (old.latitude != widget.latitude || old.longitude != widget.longitude) {
      final oldPos = LatLng(old.latitude, old.longitude);
      final newPos = LatLng(widget.latitude, widget.longitude);
      final dist = calculateDistance(oldPos, newPos);
      if (dist > 2) {
        // Only animate if moved more than 2 meters
        _animateBikePosition(oldPos, newPos);
      } else {
        _targetBikePos = newPos;
      }
      _mapController.move(newPos, _mapController.camera.zoom);
    }

    // Trigger route animation when navigation route changes
    if (widget.navigationRoute.length >= 2 &&
        widget.navigationRoute != old.navigationRoute) {
      _startRouteAnimation(widget.navigationRoute);
    }
    // Clear animation when route is removed
    if (widget.navigationRoute.isEmpty && old.navigationRoute.isNotEmpty) {
      _routeAnimController?.dispose();
      _routeAnimController = null;
      _routeAnimation = null;
      _animatedRoutePoints = [];
    }

    // Init user pulse if user location just appeared
    if (widget.userLatitude != null && old.userLatitude == null) {
      _initUserPulse();
    }
    if (widget.userLatitude == null && old.userLatitude != null) {
      _userPulseController?.dispose();
      _userPulseController = null;
      _userPulseAnimation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          _positionAnimation != null
              ? AnimatedBuilder(
                  animation: _positionAnimation!,
                  builder: (context, _) => _buildMap(_interpolatedBikePos),
                )
              : _buildMap(LatLng(widget.latitude, widget.longitude)),
          // Source labels
          _buildSourceLabels(),
          // Map controls overlay
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.pedal_bike,
                  tooltip: 'Fokus Sepeda',
                  color: const Color(0xff0f766e),
                  onTap: () => _mapController.move(
                    LatLng(widget.latitude, widget.longitude),
                    16,
                  ),
                ),
                if (widget.userLatitude != null) ...[
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.my_location,
                    tooltip: 'Fokus Saya',
                    color: const Color(0xff2563eb),
                    onTap: () => _mapController.move(
                      LatLng(widget.userLatitude!, widget.userLongitude!),
                      16,
                    ),
                  ),
                ],
                if (widget.userLatitude != null) ...[
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.zoom_out_map,
                    tooltip: 'Lihat Semua',
                    color: const Color(0xff6b7280),
                    onTap: _fitBounds,
                  ),
                ],
              ],
            ),
          ),
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

  void _fitBounds() {
    final points = <LatLng>[LatLng(widget.latitude, widget.longitude)];
    if (widget.userLatitude != null && widget.userLongitude != null) {
      points.add(LatLng(widget.userLatitude!, widget.userLongitude!));
    }
    if (points.length < 2) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
        maxZoom: 17,
      ),
    );
  }

  Widget _buildMap(LatLng bikePos) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: bikePos, initialZoom: 16),
      children: [
        _buildTileLayer(),
        if (widget.mapType == MapType.hybrid) _buildHybridLabelLayer(),
        // Path history (bike trail from backend)
        if (widget.pathHistory.length >= 2) _buildPathHistory(),
        if (widget.navigationRoute.length >= 2) _buildNavigationRoute(),
        if (widget.navigationRoute.length >= 2 && _routeAnimation != null)
          _buildAnimatedNavigationOverlay(),
        if (widget.routePoints.length >= 2) _buildRouteLayer(),
        if (widget.pickupPoint != null) _buildPickupMarker(),
        if (widget.routePoints.isNotEmpty) _buildStartMarker(),
        if (widget.routePoints.length > 1) _buildRoutePointMarkers(),
        _buildSpotMarkers(),
        if (widget.accuracyRadius > 0) _buildAccuracyCircle(bikePos),
        // User location blue dot
        if (widget.userLatitude != null && widget.userLongitude != null)
          _buildUserMarker(),
        // Bike marker: only show when backend has real GPS data
        if (widget.bikeLabel != null) _buildBikeMarker(bikePos),
        // Available bikes markers
        if (widget.availableBikes.isNotEmpty) _buildAvailableBikeMarkers(),
      ],
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

  /// Path history: the trail already traveled by the bike (from backend data)
  PolylineLayer _buildPathHistory() {
    final isSatellite = widget.mapType != MapType.standard;
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.pathHistory,
          color: isSatellite
              ? const Color(0xff94a3b8).withValues(alpha: 0.7)
              : const Color(0xff14b8a6).withValues(alpha: 0.4),
          strokeWidth: 4,
          borderColor: isSatellite
              ? const Color(0xff64748b).withValues(alpha: 0.3)
              : const Color(0xff0d9488).withValues(alpha: 0.15),
          borderStrokeWidth: 1.5,
        ),
      ],
    );
  }

  PolylineLayer _buildNavigationRoute() {
    // Base route: shown as faint guideline
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.navigationRoute,
          color: const Color(0xff3b82f6).withValues(alpha: 0.2),
          strokeWidth: 5,
          borderColor: const Color(0xff1d4ed8).withValues(alpha: 0.1),
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  /// Animated overlay: reveals the route progressively
  Widget _buildAnimatedNavigationOverlay() {
    return AnimatedBuilder(
      animation: _routeAnimation!,
      builder: (context, _) {
        final totalPoints = _animatedRoutePoints.length;
        final visibleCount = (_routeAnimation!.value * totalPoints)
            .round()
            .clamp(2, totalPoints);
        final visiblePoints = _animatedRoutePoints.sublist(0, visibleCount);

        return PolylineLayer(
          polylines: [
            Polyline(
              points: visiblePoints,
              color: const Color(0xff3b82f6),
              strokeWidth: 5,
              borderColor: const Color(0xff1d4ed8).withValues(alpha: 0.4),
              borderStrokeWidth: 2,
            ),
          ],
        );
      },
    );
  }

  PolylineLayer _buildRouteLayer() {
    final isSatellite = widget.mapType != MapType.standard;
    return PolylineLayer(
      polylines: [
        Polyline(
          points: widget.routePoints,
          color:
              widget.routeColor ??
              (isSatellite ? const Color(0xff38bdf8) : const Color(0xff0d9488)),
          strokeWidth: 4,
          borderColor:
              (widget.routeColor ??
                      (isSatellite
                          ? const Color(0xff0284c7)
                          : const Color(0xff0f766e)))
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
          height: 62,
          child: AnimatedBuilder(
            animation: _bounceAnimation!,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation!.value),
                child: child,
              );
            },
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

  /// User's own location: blue pulsing dot
  Widget _buildUserMarker() {
    final userPos = LatLng(widget.userLatitude!, widget.userLongitude!);

    if (_userPulseAnimation == null) {
      return MarkerLayer(
        markers: [
          Marker(point: userPos, width: 24, height: 24, child: _buildUserDot()),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _userPulseAnimation!,
      builder: (context, _) {
        return MarkerLayer(
          markers: [
            Marker(
              point: userPos,
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(
                        0xff3b82f6,
                      ).withValues(alpha: _userPulseAnimation!.value),
                    ),
                  ),
                  _buildUserDot(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserDot() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xff3b82f6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
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

  /// Markers for available bikes: smaller green markers, tappable
  MarkerLayer _buildAvailableBikeMarkers() {
    return MarkerLayer(
      markers: widget.availableBikes.map((bike) {
        final pos = LatLng(bike.latitude!, bike.longitude!);
        return Marker(
          point: pos,
          width: 80,
          height: 52,
          child: GestureDetector(
            onTap: () => widget.onAvailableBikeTap?.call(bike),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    bike.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff065f46),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xff10b981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Floating map control button
class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
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
