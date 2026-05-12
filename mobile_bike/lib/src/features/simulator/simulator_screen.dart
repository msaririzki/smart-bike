import 'dart:async';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../models/bike.dart';
import '../../models/device_rental_summary.dart';
import '../../services/api_client.dart';
import '../../services/gps_service.dart';
import '../../services/session_store.dart';
import 'manual_gps_panel.dart';
import 'device_details_screen.dart';
import 'mock_route_service.dart';
import 'qr_rental_panel.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({
    required this.api,
    required this.session,
    required this.onLoggedOut,
    super.key,
  });

  final ApiClient api;
  final SessionStore session;
  final VoidCallback onLoggedOut;

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  static const double _maxAcceptedGpsAccuracyMeters = 25;
  static const double _maxAcceptedJumpSpeedKmh = 80;
  static const double _minRouteDistanceMeters = 10;
  static const double _maxDynamicMovementThresholdMeters = 35;
  static const double _minReliableSpeedKmh = 2;
  static const Duration _stationaryServerPingInterval = Duration(seconds: 15);
  static const int _maxRoutePoints = 120;

  final _gps = GpsService();
  final _battery = Battery();
  final _mockService = MockRouteService();

  Bike? _bike;
  DeviceRentalSummary? _summary;
  bool _loadingBike = true;

  bool _streaming = false;
  bool _isSimulating = false;
  bool _sending = false;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ConnectivityResult>>? _networkSub;
  Timer? _heartbeatTimer;
  Timer? _batteryTimer;
  Timer? _summaryTimer;
  Timer? _clockTimer;
  Timer? _mockTimer;
  Timer? _realGpsRefreshTimer;

  double? _speedKmh;
  double? _accuracyMeters;
  String _networkType = 'unknown';
  int _batteryPercent = 0;
  DateTime? _lastGpsReadAt;
  DateTime? _lastSentAt;
  DateTime _now = DateTime.now();
  int? _activeRentalId;
  String _lastServerMsg = 'Belum ada pengiriman';
  String _simulationProgress = '';
  int _currentInterval = 5;
  SimulationMode _currentMode = SimulationMode.loop;
  String _locationMode = 'Belum aktif';
  bool _checkingLocationAccess = true;
  bool _locationAccessGranted = false;
  bool _autoStartAttempted = false;
  bool _idleDialogOpen = false;
  String? _lastIdleAlertKey;
  LocationAccessStatus _locationAccessStatus = LocationAccessStatus.denied;
  String _locationAccessMessage = 'Mengecek akses lokasi perangkat...';
  final List<_RoutePoint> _routePoints = [];
  _RoutePoint? _lastAcceptedGpsPoint;
  DateTime? _lastStationarySentAt;
  _BikeMapType _mapType = _BikeMapType.standard;

  bool get _hasActiveRental => _summary?.rental != null;

  @override
  void initState() {
    super.initState();
    _loadBike();
    _loadRentalSummary();
    _ensureLocationReady(requestIfDenied: true, showMessage: false);
    _listenNetwork();
    _loadBattery();
    _summaryTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadRentalSummary(silent: true),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _stopStream();
    _networkSub?.cancel();
    _batteryTimer?.cancel();
    _summaryTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBike() async {
    try {
      final bike = await widget.api.currentAssignment();
      if (mounted) setState(() => _bike = bike);
      _autoStartRealGpsIfReady();
    } catch (e) {
      _showMessage('Gagal memuat sepeda: $e');
    } finally {
      if (mounted) setState(() => _loadingBike = false);
    }
  }

  Future<void> _loadRentalSummary({bool silent = false}) async {
    try {
      final summary = await widget.api.activeRentalSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _bike = summary.bike ?? _bike;
        final nextRentalId = summary.rental?.id;
        if (_activeRentalId != null && nextRentalId != _activeRentalId) {
          _routePoints.clear();
          _lastAcceptedGpsPoint = null;
          _lastStationarySentAt = null;
        }
        _activeRentalId = nextRentalId;
      });
      _handleIdleAlert(summary.rental);
    } catch (e) {
      if (!silent) _showMessage('Gagal memuat ringkasan rental: $e');
    }
  }

  void _handleIdleAlert(ActiveBikeRental? rental) {
    if (!mounted) return;

    if (rental == null || !_isIdleAlertStatus(rental.status)) {
      _lastIdleAlertKey = null;
      if (_idleDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _idleDialogOpen = false;
      }
      return;
    }

    final alertKey = '${rental.id}:${rental.status}';
    if (_idleDialogOpen || _lastIdleAlertKey == alertKey) return;

    _lastIdleAlertKey = alertKey;
    _showIdleAlertDialog(rental);
  }

  void _showIdleAlertDialog(ActiveBikeRental rental) {
    _idleDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isBilling = rental.status == 'idle_billing';
        return AlertDialog(
          icon: Icon(
            isBilling
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_rounded,
            color:
                isBilling ? const Color(0xFFB42318) : const Color(0xFFB54708),
            size: 42,
          ),
          title: Text(isBilling ? 'Biaya Diam Berjalan' : 'Sepeda Diam'),
          content: Text(
            isBilling
                ? 'Sepeda masih tidak bergerak. Biaya idle sedang berjalan dan akan tampil juga di aplikasi pengguna.'
                : 'Sepeda berhenti terlalu lama. Pastikan pengguna melihat peringatan di aplikasi atau segera lanjutkan perjalanan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Saya Mengerti'),
            ),
          ],
        );
      },
    ).whenComplete(() => _idleDialogOpen = false);
  }

  void _listenNetwork() {
    _networkSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _networkType = _connectivityLabel(results));
    });
    Connectivity().checkConnectivity().then((results) {
      if (mounted) setState(() => _networkType = _connectivityLabel(results));
    });
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryPercent = level);
      _batteryTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
        final nextLevel = await _battery.batteryLevel;
        if (mounted) setState(() => _batteryPercent = nextLevel);
      });
    } catch (_) {
      if (mounted) setState(() => _batteryPercent = 0);
    }
  }

  String _connectivityLabel(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile)) return '4G/3G';
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Offline';
  }

  Future<bool> _ensureLocationReady({
    required bool requestIfDenied,
    bool showMessage = true,
  }) async {
    if (mounted) setState(() => _checkingLocationAccess = true);

    final access = await _gps.ensureLocationAccess(
      requestIfDenied: requestIfDenied,
    );
    final message = _locationAccessText(access.status);

    if (!mounted) return access.granted;
    setState(() {
      _checkingLocationAccess = false;
      _locationAccessGranted = access.granted;
      _locationAccessStatus = access.status;
      _locationAccessMessage = message;
    });

    if (!access.granted && showMessage) {
      _showMessage(message);
    }

    if (access.granted) {
      _autoStartRealGpsIfReady();
    }

    return access.granted;
  }

  void _autoStartRealGpsIfReady() {
    if (_autoStartAttempted || _bike == null || !_locationAccessGranted) {
      return;
    }
    if (_streaming || _isSimulating) return;

    _autoStartAttempted = true;
    _startStream(requestPermission: false);
  }

  Future<void> _openLocationSettings() async {
    if (_locationAccessStatus == LocationAccessStatus.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }

    await _ensureLocationReady(requestIfDenied: false, showMessage: false);
  }

  String _locationAccessText(LocationAccessStatus status) {
    return switch (status) {
      LocationAccessStatus.granted =>
        'Akses lokasi aktif. GPS real siap dikirim ke server.',
      LocationAccessStatus.serviceDisabled =>
        'GPS perangkat belum aktif. Nyalakan Lokasi/GPS di pengaturan HP.',
      LocationAccessStatus.denied =>
        'Izin lokasi ditolak. Berikan izin lokasi agar sepeda bisa mengirim GPS real.',
      LocationAccessStatus.deniedForever =>
        'Izin lokasi diblokir permanen. Buka pengaturan aplikasi lalu izinkan Lokasi.',
    };
  }

  Future<void> _startStream({bool requestPermission = true}) async {
    if (_isSimulating) _stopSimulation();

    final granted = requestPermission
        ? await _ensureLocationReady(requestIfDenied: true)
        : _locationAccessGranted;
    if (!granted) {
      return;
    }

    _stopRealGps();
    setState(() {
      _streaming = true;
      _locationMode = 'Real GPS';
    });

    final currentPosition = await _gps.getCurrentPosition();
    if (currentPosition != null) {
      _handleRealGpsPosition(currentPosition);
    }

    _positionSub = _gps.positionStream().listen((pos) {
      if (!mounted) return;
      _handleRealGpsPosition(pos);
    }, onError: (Object error) {
      if (!mounted) return;
      setState(() {
        _streaming = false;
        _locationMode = 'GPS error';
        _lastServerMsg = 'GPS gagal: $error';
      });
      _showMessage('Stream GPS berhenti: $error');
    });

    _startRealGpsRefresh();
    _startHeartbeat();
  }

  void _startRealGpsRefresh() {
    _realGpsRefreshTimer?.cancel();
    _realGpsRefreshTimer = Timer.periodic(
      Duration(seconds: _currentInterval),
      (_) => _refreshRealGpsPosition(),
    );
  }

  Future<void> _refreshRealGpsPosition() async {
    if (!_streaming || _isSimulating || _sending) return;

    final currentPosition = await _gps.getCurrentPosition();
    if (!mounted || currentPosition == null) return;

    _handleRealGpsPosition(currentPosition);
  }

  void _handleRealGpsPosition(Position pos) {
    final sampledAt = pos.timestamp.toLocal();

    setState(() {
      _accuracyMeters = pos.accuracy;
      _lastGpsReadAt = sampledAt;
      _locationMode = 'Real GPS';
    });

    if (pos.accuracy > _maxAcceptedGpsAccuracyMeters) {
      setState(() {
        _speedKmh = 0;
        _lastServerMsg =
            'GPS kurang akurat (${pos.accuracy.toStringAsFixed(1)} m), titik diabaikan';
      });
      return;
    }

    if (!_hasActiveRental) {
      setState(() => _speedKmh = 0);
      _sendLocation(pos, speedKmh: 0);
      return;
    }

    final previous = _lastAcceptedGpsPoint;
    if (previous == null) {
      _acceptRealGpsPoint(pos, speedKmh: 0, message: 'Baseline GPS disimpan.');
      return;
    }

    final distance = _haversineMeters(
      previous.latitude,
      previous.longitude,
      pos.latitude,
      pos.longitude,
    );
    final seconds = sampledAt.difference(previous.recordedAt).inMilliseconds /
        Duration.millisecondsPerSecond;
    final impliedSpeedKmh = seconds <= 0 ? 0.0 : (distance / seconds) * 3.6;
    final movementThreshold = _movementThresholdMeters(pos, previous);

    if (distance < movementThreshold) {
      setState(() {
        _speedKmh = 0;
        _lastServerMsg =
            'GPS stabil: perpindahan ${distance.toStringAsFixed(1)} m dianggap diam';
      });
      _sendStationaryPingIfDue(previous, pos);
      return;
    }

    if (impliedSpeedKmh > _maxAcceptedJumpSpeedKmh) {
      setState(() {
        _speedKmh = 0;
        _lastServerMsg =
            'GPS loncat, titik diabaikan (${impliedSpeedKmh.toStringAsFixed(1)} km/h)';
      });
      return;
    }

    final speedKmh = _displaySpeedKmh(pos, impliedSpeedKmh);
    _acceptRealGpsPoint(
      pos,
      speedKmh: speedKmh,
      message: 'GPS valid, pergerakan ${distance.toStringAsFixed(1)} m.',
    );
  }

  void _stopStream() {
    _stopSimulation();
    _stopRealGps();
    _stopHeartbeat();
    if (mounted) {
      setState(() {
        _streaming = false;
        _locationMode = 'Belum aktif';
      });
    }
  }

  void _stopRealGps() {
    _positionSub?.cancel();
    _positionSub = null;
    _realGpsRefreshTimer?.cancel();
    _realGpsRefreshTimer = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendManualCoordinate(double lat, double lng) {
    _sendCoordinate(
      latitude: lat,
      longitude: lng,
      speedKmh: 0,
      accuracyMeters: 0,
      mode: 'Manual GPS',
    );
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    _stopRealGps();
    _mockService.reset();
    setState(() {
      _isSimulating = true;
      _streaming = true;
      _locationMode = 'Mock Route';
      _updateSimulationProgress();
    });
    _startHeartbeat();

    _sendMockPoint();
    _mockTimer = Timer.periodic(
      Duration(seconds: _currentInterval),
      (_) => _sendNextMockPoint(),
    );
  }

  void _sendNextMockPoint() {
    if (_mockService.hasNext) {
      _mockService.next(mode: _currentMode);
      _sendMockPoint();
      return;
    }

    if (_currentMode == SimulationMode.stopAtEnd) {
      _stopSimulation();
      return;
    }

    if (_currentMode == SimulationMode.reset) {
      _mockService.reset();
      _sendMockPoint();
      _stopSimulation();
      return;
    }

    _mockService.next(mode: _currentMode);
    _sendMockPoint();
  }

  void _sendMockPoint() {
    final point = _mockService.currentPoint;
    _sendCoordinate(
      latitude: point.latitude,
      longitude: point.longitude,
      speedKmh: 0,
      accuracyMeters: 0,
      mode: 'Mock Route',
    );
    if (mounted) setState(_updateSimulationProgress);
  }

  void _stopSimulation() {
    _mockTimer?.cancel();
    _mockTimer = null;
    if (mounted) {
      setState(() {
        _isSimulating = false;
        _simulationProgress = '';
      });
    }
  }

  void _updateSimulationProgress() {
    _simulationProgress =
        'Simulasi Rute: Titik ${_mockService.currentIndex + 1}/${_mockService.totalPoints}';
  }

  void _sendCoordinate({
    required double latitude,
    required double longitude,
    required double speedKmh,
    required double accuracyMeters,
    required String mode,
  }) {
    setState(() {
      _speedKmh = speedKmh;
      _accuracyMeters = accuracyMeters;
      _lastGpsReadAt = DateTime.now();
      _locationMode = mode;
      _addRoutePoint(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        source: mode,
      );
    });

    final pos = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracyMeters,
      altitude: 0,
      heading: 0,
      speed: speedKmh / 3.6,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    _sendLocation(pos);
  }

  double _displaySpeedKmh(Position pos, double impliedSpeedKmh) {
    final gpsSpeedKmh =
        pos.speed.isFinite && pos.speed > 0 ? pos.speed * 3.6 : 0.0;

    if (gpsSpeedKmh >= _minReliableSpeedKmh &&
        gpsSpeedKmh <= _maxAcceptedJumpSpeedKmh) {
      return gpsSpeedKmh;
    }

    return impliedSpeedKmh >= _minReliableSpeedKmh ? impliedSpeedKmh : 0;
  }

  double _movementThresholdMeters(Position pos, _RoutePoint previous) {
    final dynamicThreshold =
        math.max(pos.accuracy, previous.accuracyMeters) * 1.5;

    return math.max(
      _minRouteDistanceMeters,
      math.min(_maxDynamicMovementThresholdMeters, dynamicThreshold),
    );
  }

  void _acceptRealGpsPoint(
    Position pos, {
    required double speedKmh,
    required String message,
  }) {
    final point = _RoutePoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      source: 'Real GPS',
      recordedAt: pos.timestamp.toLocal(),
    );

    _lastAcceptedGpsPoint = point;
    _lastStationarySentAt = null;

    setState(() {
      _speedKmh = speedKmh;
      _lastServerMsg = message;
      _addRoutePoint(
        latitude: point.latitude,
        longitude: point.longitude,
        accuracyMeters: point.accuracyMeters,
        source: point.source,
      );
    });

    _sendLocation(pos, speedKmh: speedKmh);
  }

  void _sendStationaryPingIfDue(_RoutePoint stablePoint, Position sample) {
    final now = DateTime.now();
    if (_lastStationarySentAt != null &&
        now.difference(_lastStationarySentAt!) <
            _stationaryServerPingInterval) {
      return;
    }

    _lastStationarySentAt = now;
    _sendLocation(
      _positionFromRoutePoint(stablePoint, sample),
      speedKmh: 0,
    );
  }

  Position _positionFromRoutePoint(_RoutePoint point, Position sample) {
    return Position(
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: sample.timestamp,
      accuracy: math.min(sample.accuracy, point.accuracyMeters),
      altitude: sample.altitude,
      heading: sample.heading,
      speed: 0,
      speedAccuracy: sample.speedAccuracy,
      altitudeAccuracy: sample.altitudeAccuracy,
      headingAccuracy: sample.headingAccuracy,
    );
  }

  Future<void> _sendLocation(Position pos, {double? speedKmh}) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final res = await widget.api.sendLocationUpdate(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: speedKmh ?? (pos.speed * 3.6),
        accuracyMeters: pos.accuracy,
        networkType: _networkType,
        recordedAt: pos.timestamp.toLocal(),
      );
      if (mounted) {
        setState(() {
          _lastSentAt = DateTime.now();
          _lastServerMsg = res['message']?.toString() ?? 'OK';
        });
        _loadRentalSummary(silent: true);
      }
    } catch (e) {
      if (mounted) setState(() => _lastServerMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _addRoutePoint({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required String source,
  }) {
    final next = _RoutePoint(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      source: source,
      recordedAt: DateTime.now(),
    );

    if (_routePoints.isNotEmpty) {
      final last = _routePoints.last;
      final distance = _haversineMeters(
        last.latitude,
        last.longitude,
        latitude,
        longitude,
      );
      if (distance < _minRouteDistanceMeters && source == 'Real GPS') {
        return;
      }
    }

    _routePoints.add(next);
    if (_routePoints.length > _maxRoutePoints) {
      _routePoints.removeRange(0, _routePoints.length - _maxRoutePoints);
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      await widget.api.sendHeartbeat(
        networkType: _networkType,
        batteryPercent: _batteryPercent,
      );
    } catch (_) {}
  }

  Future<void> _logout() async {
    _stopStream();
    try {
      await widget.api.logout();
    } catch (_) {}
    widget.onLoggedOut();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bike = _bike;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Simulator Sepeda',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: () async {
              await _loadBike();
              await _loadRentalSummary();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loadingBike
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : bike == null
              ? _buildNoBikeView()
              : _buildDashboardView(bike),
    );
  }

  Widget _buildNoBikeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pedal_bike_rounded,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada sepeda yang di-assign ke akun ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungi admin untuk menghubungkan akun device dengan sepeda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667085)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadBike,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView(Bike bike) {
    final rental = _summary?.rental;

    return Stack(
      children: [
        Positioned.fill(
          child: _MiniRouteMap(
            points: List.unmodifiable(_routePoints),
            latestAccuracyMeters: _accuracyMeters,
            mapType: _mapType,
            onMapTypeChanged: (type) => setState(() => _mapType = type),
          ),
        ),
        _DashboardOverlay(
          bike: bike,
          rental: rental,
          speedKmh: _speedKmh ?? 0,
          accuracyMeters: _accuracyMeters,
          networkType: _networkType,
          batteryPercent: _batteryPercent,
          streaming: _streaming,
          isSimulating: _isSimulating,
          simulationProgress: _simulationProgress,
          currentInterval: _currentInterval,
          currentMode: _currentMode,
          pointsSent: _pointsSent,
          lastSentAt: _lastSentAt,
          locationMode: _locationMode,
          now: _now,
          lastServerMsg: _lastServerMsg,
          onToggleStream: () =>
              _streaming ? _stopStream() : _startStream(requestPermission: true),
          onToggleSimulation: _toggleSimulation,
          onSendManual: _sendManualCoordinate,
          onIntervalChanged: (v) => setState(() => _currentInterval = v),
            height: MediaQuery.of(context).size.height,
            points: List.unmodifiable(_routePoints),
            latestAccuracyMeters:
                _accuracyMeters ?? rental?.latestLocationPoint?.accuracyMeters,
            mapType: _mapType,
            onMapTypeChanged: (value) => setState(() => _mapType = value),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: _buildTopOverlay(bike, isRented: true),
        ),
        if (rental != null && _isIdleAlertStatus(rental.status))
          Positioned(
            top: MediaQuery.of(context).padding.top + 140,
            left: 16,
            right: 16,
            child: _IdleAlertBanner(rental: rental),
          ),
        if (_checkingLocationAccess || !_locationAccessGranted)
          Positioned(
            top: MediaQuery.of(context).padding.top +
                (_isIdleAlertStatus(rental.status) ? 230 : 140),
            left: 16,
            right: 16,
            child: _LocationAccessBanner(
              checking: _checkingLocationAccess,
              status: _locationAccessStatus,
              message: _locationAccessMessage,
              onRequestPermission: () =>
                  _ensureLocationReady(requestIfDenied: true),
              onOpenSettings: _openLocationSettings,
            ),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 140,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    (_speedKmh ?? rental.currentSpeedKmh ?? 0.0)
                        .toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('km/h',
                      style: TextStyle(fontSize: 18, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 220,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              color: const Color(0xff1f2937),
              onPressed: () {},
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ModernStatColumn(
                      icon: Icons.timer_outlined,
                      label: 'Durasi Sewa',
                      value: _formatDuration(rental.startedAt, _now),
                      iconColor: const Color(0xff10b981),
                    ),
                    Container(
                        width: 1, height: 40, color: const Color(0xfff3f4f6)),
                    _ModernStatColumn(
                      icon: Icons.route_outlined,
                      label: 'Jarak',
                      value:
                          '${(rental.totalDistanceKilometers).toStringAsFixed(2)} km',
                      iconColor: const Color(0xff10b981),
                    ),
                    Container(
                        width: 1, height: 40, color: const Color(0xfff3f4f6)),
                    _ModernStatColumn(
                      icon: Icons.attach_money,
                      label: 'Estimasi Biaya',
                      value: _formatRupiah(rental.totalCost),
                      iconColor: const Color(0xff10b981),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopOverlay(Bike bike, {bool isRented = true}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu Button
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: const Color(0xff1f2937),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) =>
                        _buildAdvancedControlsModal(bike, _summary?.rental),
                  );
                },
              ),
            ),
            // Logo
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pedal_bike,
                        color: Color(0xff10b981), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'FlowBike',
                      style: TextStyle(
                        color:
                            isRented ? const Color(0xff065f46) : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Sewa Pintar. Lacak Akurat.',
                  style: TextStyle(
                      color: isRented
                          ? const Color(0xff4b5563)
                          : const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            // Help/Status button
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.power_settings_new_rounded),
                color: const Color(0xff1f2937),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Keluar dari Simulator?'),
                      content: const Text(
                          'Sesi penyewaan dan pelacakan GPS akan dihentikan jika Anda keluar.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _logout();
                          },
                          child: const Text('Keluar',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedControlsModal(Bike bike, ActiveBikeRental? rental) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: const Color(0xffd1d5db),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Pengaturan Lanjutan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _StatusBanner(
                    streaming: _streaming,
                    mode: _locationMode,
                    sending: _sending,
                    serverMessage: _lastServerMsg,
                    lastGpsReadAt: _lastGpsReadAt,
                    lastSentAt: _lastSentAt,
                  ),
                  const SizedBox(height: 12),
                  QrRentalPanel(
                    api: widget.api,
                    hasAssignedBike: true,
                    hasActiveRental: rental != null,
                  ),
                  const SizedBox(height: 12),
                  _FieldTestChecklist(
                    locationAccess: _locationAccessGranted,
                    gpsEnabled: _locationAccessStatus !=
                        LocationAccessStatus.serviceDisabled,
                    autoStart: _streaming,
                    networkType: _networkType,
                    lastGpsAt: _lastGpsReadAt,
                    lastServerAt: _lastSentAt,
                    accuracyMeters: _accuracyMeters ??
                        rental?.latestLocationPoint?.accuracyMeters,
                    rentalActive: rental != null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _streaming
                        ? () {
                            Navigator.pop(context);
                            _sendHeartbeat();
                          }
                        : null,
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: const Text('Kirim Heartbeat Manual'),
                  ),
                  const SizedBox(height: 12),
                  _buildDebugPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return _Panel(
      padding: const EdgeInsets.all(12),
      borderColor: const Color(0xFF99F6E4),
      backgroundColor: const Color(0xFFF0FDFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0F766E),
                ),
>>>>>>> 85841e002c40e0ba54cda30f0445745c278a5aaf
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusBanner(
                    streaming: _streaming,
                    mode: _locationMode,
                    sending: _sending,
                    serverMessage: _lastServerMsg,
                    lastGpsReadAt: _lastGpsReadAt,
                    lastSentAt: _lastSentAt,
                  ),
                  if (rental != null && _isIdleAlertStatus(rental.status)) ...[
                    const SizedBox(height: 8),
                    _IdleAlertBanner(rental: rental),
                  ],
                  if (_checkingLocationAccess || !_locationAccessGranted) ...[
                    const SizedBox(height: 8),
                    _LocationAccessBanner(
                      checking: _checkingLocationAccess,
                      status: _locationAccessStatus,
                      message: _locationAccessMessage,
                      onRequestPermission: () => _ensureLocationReady(
                        requestIfDenied: true,
                      ),
                      onOpenSettings: _openLocationSettings,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: Color(0xFF38BDF8)),
                      SizedBox(width: 5),
                      Text(
                        'Titik Awal',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 24),
                      _LegendDot(color: Color(0xFF22C55E)),
                      SizedBox(width: 5),
                      Text(
                        'Titik Terbaru',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                  child: Row(
                    children: [
                      _MetricItemLarge(
                        label: 'SPEED',
                        value: displaySpeed.toStringAsFixed(1),
                        unit: 'km/h',
                        icon: Icons.speed_rounded,
                        color: const Color(0xFF2F9E38),
                      ),
                      Container(width: 1, height: 30, color: const Color(0xFFF2F4F7)),
                      _MetricItemLarge(
                        label: 'JARAK',
                        value: (rental?.totalDistanceKilometers ?? 0).toStringAsFixed(2),
                        unit: 'km',
                        icon: Icons.route_rounded,
                        color: const Color(0xFF38BDF8),
                      ),
                      Container(width: 1, height: 30, color: const Color(0xFFF2F4F7)),
                      _MetricItemLarge(
                        label: 'BIAYA',
                        value: _formatRupiah(rental?.totalCost ?? 0).replaceAll('Rp', ''),
                        unit: 'Rp',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF2F4F7)),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailsScreen(
                          api: widget.api,
                          bike: bike,
                          rental: rental,
                          displaySpeed: displaySpeed,
                          batteryPercent: _batteryPercent,
                          networkType: _networkType,
                          pointsSent: _pointsSent,
                          lastSentAt: _lastSentAt,
                          locationMode: _locationMode,
                          streaming: _streaming,
                          now: _now,
                          locationAccessGranted: _locationAccessGranted,
                          locationAccessStatus: _locationAccessStatus,
                          lastGpsReadAt: _lastGpsReadAt,
                          accuracyMeters: _accuracyMeters ?? rental?.latestLocationPoint?.accuracyMeters,
                        ),
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.electric_bike_rounded, color: Color(0xFF2F9E38), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Perangkat & Rental',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF101828)),
                              ),
                              Text(
                                '${bike.code} • Baterai $_batteryPercent%',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF667085), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldTestChecklist extends StatelessWidget {
  const _FieldTestChecklist({
    required this.locationAccess,
    required this.gpsEnabled,
    required this.autoStart,
    required this.networkType,
    required this.lastGpsAt,
    required this.lastServerAt,
    required this.accuracyMeters,
    required this.rentalActive,
  });

  final bool locationAccess;
  final bool gpsEnabled;
  final bool autoStart;
  final String networkType;
  final DateTime? lastGpsAt;
  final DateTime? lastServerAt;
  final double? accuracyMeters;
  final bool rentalActive;

  @override
  Widget build(BuildContext context) {
    final accuracyOk = accuracyMeters != null && accuracyMeters! <= 50;
    final gpsFresh = _isFresh(lastGpsAt, const Duration(seconds: 15));
    final serverFresh = _isFresh(lastServerAt, const Duration(seconds: 15));

    return _Panel(
      borderColor: const Color(0xFFD0D5DD),
      backgroundColor: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checklist Tes Lapangan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            ok: locationAccess,
            label: 'Izin lokasi',
            detail: locationAccess ? 'Diizinkan' : 'Belum diizinkan',
          ),
          _CheckRow(
            ok: gpsEnabled,
            label: 'GPS perangkat',
            detail: gpsEnabled ? 'Aktif' : 'GPS HP belum aktif',
          ),
          _CheckRow(
            ok: autoStart,
            label: 'Tracking otomatis',
            detail: autoStart ? 'Berjalan' : 'Belum berjalan',
          ),
          _CheckRow(
            ok: networkType != 'Offline',
            label: 'Jaringan',
            detail: networkType,
          ),
          _CheckRow(
            ok: gpsFresh,
            label: 'GPS dibaca',
            detail: _relativeTimeLabel(lastGpsAt),
          ),
          _CheckRow(
            ok: serverFresh,
            label: 'Server menerima',
            detail: _relativeTimeLabel(lastServerAt),
          ),
          _CheckRow(
            ok: accuracyOk,
            label: 'Akurasi GPS',
            detail: accuracyMeters == null
                ? 'Belum ada data'
                : '${accuracyMeters!.toStringAsFixed(0)} m',
          ),
          _CheckRow(
            ok: rentalActive,
            label: 'Rental aktif',
            detail: rentalActive ? 'Ada rental berjalan' : 'Monitoring saja',
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.ok,
    required this.label,
    required this.detail,
  });

  final bool ok;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF027A48) : const Color(0xFFB54708);
    final background = ok ? const Color(0xFFECFDF3) : const Color(0xFFFFFAEB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration:
                BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(
              ok ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
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

class _LocationAccessBanner extends StatelessWidget {
  const _LocationAccessBanner({
    required this.checking,
    required this.status,
    required this.message,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final bool checking;
  final LocationAccessStatus status;
  final String message;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final needsAppSettings = status == LocationAccessStatus.deniedForever;
    final needsLocationSettings =
        status == LocationAccessStatus.serviceDisabled || needsAppSettings;

    return _Panel(
      borderColor: const Color(0xFFFDB022),
      backgroundColor: const Color(0xFFFFFCF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFB54708),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  checking ? 'Mengecek akses lokasi...' : message,
                  style: const TextStyle(
                    color: Color(0xFF7A2E0E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!checking) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: const Text('Minta Izin Lokasi'),
                ),
                if (needsLocationSettings)
                  TextButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: Text(
                      needsAppSettings
                          ? 'Buka Pengaturan Aplikasi'
                          : 'Aktifkan GPS',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.streaming,
    required this.mode,
    required this.sending,
    required this.serverMessage,
    required this.lastGpsReadAt,
    required this.lastSentAt,
  });

  final bool streaming;
  final String mode;
  final bool sending;
  final String serverMessage;
  final DateTime? lastGpsReadAt;
  final DateTime? lastSentAt;

  @override
  Widget build(BuildContext context) {
    final color = streaming ? const Color(0xFF027A48) : const Color(0xFFB42318);
    final title = streaming ? 'GPS aktif otomatis' : 'GPS otomatis berhenti';
    final subtitle = streaming
        ? 'Mode: $mode | GPS: ${_relativeTimeLabel(lastGpsReadAt)} | Server: ${_relativeTimeLabel(lastSentAt)}'
        : 'Mode: $mode | Server: $serverMessage';

    return _Panel(
      child: Row(
        children: [
          _StatusDot(active: streaming),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (sending)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (!sending && streaming)
            const Icon(Icons.sensors_rounded, color: Color(0xFF0F766E)),
        ],
      ),
    );
  }
}

class _IdleAlertBanner extends StatelessWidget {
  const _IdleAlertBanner({required this.rental});

  final ActiveBikeRental rental;

  @override
  Widget build(BuildContext context) {
    final isBilling = rental.status == 'idle_billing';
    final background =
        isBilling ? const Color(0xFFFEF3F2) : const Color(0xFFFFFAEB);
    final border =
        isBilling ? const Color(0xFFFECDCA) : const Color(0xFFFEDF89);
    final iconColor =
        isBilling ? const Color(0xFFB42318) : const Color(0xFFB54708);
    final title =
        isBilling ? 'Biaya idle sedang berjalan' : 'Sepeda diam terlalu lama';
    final message = isBilling
        ? 'Peringatan sudah naik menjadi denda diam. Total biaya idle: ${_formatRupiah(rental.idleCost)}.'
        : 'Minta pengguna mengecek aplikasi mobile_user atau lanjutkan perjalanan agar denda diam tidak berjalan.';

    return _Panel(
      borderColor: border,
      backgroundColor: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isBilling
                  ? Icons.warning_amber_rounded
                  : Icons.notifications_active_rounded,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint {
  const _RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.source,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String source;
  final DateTime recordedAt;
}

class _ModernStatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _ModernStatColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? const Color(0xff9ca3af), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xff1f2937),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff6b7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DeviceAndRentalSummary extends StatelessWidget {
  const _DeviceAndRentalSummary({
    required this.bike,
    required this.rental,
    required this.batteryPercent,
    required this.networkType,
    required this.pointsSent,
    required this.lastSentAt,
    required this.locationMode,
    required this.streaming,
    required this.now,
  });

  final Bike bike;
  final ActiveBikeRental? rental;
  final int batteryPercent;
  final String networkType;
  final int pointsSent;
  final DateTime? lastSentAt;
  final String locationMode;
  final bool streaming;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pedal_bike_rounded,
                  size: 18, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                '${bike.code} - ${bike.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                    fontSize: 13),
              ),
              const Spacer(),
              if (rental != null)
                _Badge(label: _rentalStatusLabel(rental!.status)),
            ],
          ),
          const Divider(height: 16),
          _MetricGridCompact(
            children: [
              _MetricItemLarge(
                  label: 'Baterai',
                  value: '$batteryPercent',
                  unit: '%',
                  icon: Icons.battery_std,
                  color: const Color(0xFF667085)),
              _MetricItemLarge(
                  label: 'Jaringan',
                  value: networkType,
                  unit: '',
                  icon: Icons.network_check,
                  color: const Color(0xFF667085)),
              _MetricItemLarge(
                  label: 'Titik',
                  value: '$pointsSent',
                  unit: '',
                  icon: Icons.upload,
                  color: const Color(0xFF667085)),
              _MetricItemLarge(
                  label: 'Mode',
                  value: locationMode,
                  unit: '',
                  icon: Icons.explore_outlined,
                  color: const Color(0xFF667085)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGridCompact extends StatelessWidget {
  const _MetricGridCompact({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }
}

class _MetricItemLarge extends StatelessWidget {
  const _MetricItemLarge({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                if (unit == 'Rp')
                  TextSpan(
                    text: 'Rp ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828).withOpacity(0.5),
                    ),
                  ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF101828),
                  ),
                ),
                if (unit != 'Rp' && unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF667085),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendChip extends StatelessWidget {
  const _MapLegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BikeMapType {
  standard('Standar'),
  satellite('Satelit');

  const _BikeMapType(this.label);

  final String label;
}

class _MiniRouteMap extends StatelessWidget {
  const _MiniRouteMap({
    this.height = 170,
    required this.points,
    required this.latestAccuracyMeters,
    required this.mapType,
    required this.onMapTypeChanged,
  });

  final double height;
  final List<_RoutePoint> points;
  final double? latestAccuracyMeters;
  final _BikeMapType mapType;
  final ValueChanged<_BikeMapType> onMapTypeChanged;

  static const _fallbackCenter = latlong.LatLng(-8.583235, 116.116768);

  @override
  Widget build(BuildContext context) {
    final mapPoints = points
        .map((point) => latlong.LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final latestPoint = mapPoints.isEmpty ? _fallbackCenter : mapPoints.last;
    final pointCount = points.length;
    final isSatellite = mapType == _BikeMapType.satellite;
    final routeColor =
        isSatellite ? const Color(0xFF22D3EE) : const Color(0xFF0EA5E9);
    final latestAccuracy = latestAccuracyMeters;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              key: ValueKey(
                'bike-map-${mapType.name}-$pointCount-'
                '${latestPoint.latitude.toStringAsFixed(6)}-'
                '${latestPoint.longitude.toStringAsFixed(6)}',
              ),
              options: MapOptions(
                initialCenter: latestPoint,
                initialZoom: pointCount == 0 ? 15 : 17,
                minZoom: 5,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                _buildTileLayer(),
                if (isSatellite) _buildLabelLayer(),
                if (mapPoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: mapPoints,
                        strokeWidth: 7,
                        color: routeColor.withValues(alpha: .28),
                      ),
                      Polyline(
                        points: mapPoints,
                        strokeWidth: 4,
                        color: routeColor,
                      ),
                    ],
                  ),
                if (latestAccuracy != null &&
                    latestAccuracy > 0 &&
                    mapPoints.isNotEmpty)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: latestPoint,
                        radius: latestAccuracy.clamp(5, 100).toDouble(),
                        useRadiusInMeter: true,
                        color: const Color(0x3322C55E),
                        borderColor: const Color(0xFF22C55E),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (mapPoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      if (mapPoints.length > 1)
                        _buildMarker(
                          point: mapPoints.first,
                          icon: Icons.trip_origin,
                          color: const Color(0xFF38BDF8),
                          size: 34,
                        ),
                      _buildMarker(
                        point: latestPoint,
                        icon: Icons.navigation_rounded,
                        color: const Color(0xFF22C55E),
                        size: 42,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 100,
            child: _MapChip(
              icon: Icons.route_outlined,
              label: pointCount == 0 ? 'Jalur belum ada' : '$pointCount titik',
            ),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 100,
            child: _MapChip(
              icon: Icons.gps_fixed,
              label: latestAccuracyMeters == null
                  ? 'GPS -'
                  : '${latestAccuracyMeters!.toStringAsFixed(0)} m',
            ),
          ),
          Positioned(
            right: 12,
            bottom: 42,
            child: _MapTypeToggle(
              value: mapType,
              onChanged: onMapTypeChanged,
            ),
          ),
          if (pointCount < 2)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  pointCount == 0
                      ? 'Menunggu titik GPS valid dari perangkat.'
                      : 'Jalur muncul setelah perangkat benar-benar bergerak.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  TileLayer _buildTileLayer() {
    if (mapType == _BikeMapType.satellite) {
      return TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.smartbike.mobile_bike',
        maxNativeZoom: 19,
      );
    }

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.smartbike.mobile_bike',
      maxNativeZoom: 19,
    );
  }

  TileLayer _buildLabelLayer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.smartbike.mobile_bike',
      maxNativeZoom: 19,
    );
  }

  Marker _buildMarker({
    required latlong.LatLng point,
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * .58),
      ),
    );
  }
}

class _MapTypeToggle extends StatelessWidget {
  const _MapTypeToggle({
    required this.value,
    required this.onChanged,
  });

  final _BikeMapType value;
  final ValueChanged<_BikeMapType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6020617),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _BikeMapType.values.map((type) {
          final selected = type == value;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF22C55E) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  color: selected ? const Color(0xFF052E16) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC020617),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF67E8F9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color:
            widget.active ? const Color(0xFF12B76A) : const Color(0xFFF04438),
        shape: BoxShape.circle,
      ),
    );

    if (!widget.active) return dot;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: 0.45 + (_controller.value * 0.55),
        child: dot,
      ),
    );
  }
}

String _formatRupiah(int value) {
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${value < 0 ? '-' : ''}Rp${buffer.toString()}';
}

String _timeDiff(DateTime dt) {
  final rawDiff = DateTime.now().difference(dt);
  final diff = rawDiff.isNegative ? Duration.zero : rawDiff;
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  return '${diff.inHours}j';
}

String _relativeTimeLabel(DateTime? dt) {
  if (dt == null) return 'Belum ada';
  return '${_timeDiff(dt)} lalu';
}

bool _isFresh(DateTime? dt, Duration maxAge) {
  if (dt == null) return false;
  final age = DateTime.now().difference(dt);
  return !age.isNegative && age <= maxAge;
}

double _haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0;
  final latFrom = _toRadians(lat1);
  final latTo = _toRadians(lat2);
  final latDelta = _toRadians(lat2 - lat1);
  final lonDelta = _toRadians(lon2 - lon1);

  final a = math.sin(latDelta / 2) * math.sin(latDelta / 2) +
      math.cos(latFrom) *
          math.cos(latTo) *
          math.sin(lonDelta / 2) *
          math.sin(lonDelta / 2);

  return earthRadius * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
}

double _toRadians(double degrees) => degrees * (math.pi / 180);

bool _isIdleAlertStatus(String status) {
  return status == 'idle_warning' || status == 'idle_billing';
}

String _formatDuration(DateTime? startedAt, DateTime now) {
  if (startedAt == null) return '00:00:00';
  final diff = now.difference(startedAt);
  if (diff.isNegative) return '00:00:00';
  final hours = diff.inHours.toString().padLeft(2, '0');
  final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
