import 'dart:async';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/bike.dart';
import '../../models/device_rental_summary.dart';
import '../../services/api_client.dart';
import '../../services/gps_service.dart';
import '../../services/session_store.dart';
import 'manual_gps_panel.dart';
import 'mock_route_service.dart';

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
  static const double _maxAcceptedGpsAccuracyMeters = 50;
  static const double _maxAcceptedJumpSpeedKmh = 80;
  static const double _minRouteDistanceMeters = 1.5;
  static const int _maxRoutePoints = 120;

  final _gps = GpsService();
  final _battery = Battery();
  final _mockService = MockRouteService();

  Bike? _bike;
  DeviceRentalSummary? _summary;
  bool _loadingBike = true;
  bool _loadingSummary = true;

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

  double? _lat;
  double? _lng;
  double? _speedKmh;
  double? _accuracyMeters;
  String _networkType = 'unknown';
  int _batteryPercent = 0;
  int _pointsSent = 0;
  DateTime? _lastSentAt;
  int? _activeRentalId;
  DateTime _now = DateTime.now();
  String _lastServerMsg = 'Belum ada pengiriman';
  String _simulationProgress = '';
  int _currentInterval = 5;
  SimulationMode _currentMode = SimulationMode.loop;
  String _locationMode = 'Belum aktif';
  bool _checkingLocationAccess = true;
  bool _locationAccessGranted = false;
  LocationAccessStatus _locationAccessStatus = LocationAccessStatus.denied;
  String _locationAccessMessage = 'Mengecek akses lokasi perangkat...';
  final List<_RoutePoint> _routePoints = [];

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
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _now = DateTime.now());
      },
    );
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
    } catch (e) {
      _showMessage('Gagal memuat sepeda: $e');
    } finally {
      if (mounted) setState(() => _loadingBike = false);
    }
  }

  Future<void> _loadRentalSummary({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loadingSummary = true);
    try {
      final summary = await widget.api.activeRentalSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _bike = summary.bike ?? _bike;
        final nextRentalId = summary.rental?.id;
        if (_activeRentalId != null && nextRentalId != _activeRentalId) {
          _routePoints.clear();
        }
        _activeRentalId = nextRentalId;
      });
    } catch (e) {
      if (!silent) _showMessage('Gagal memuat ringkasan rental: $e');
    } finally {
      if (!silent && mounted) setState(() => _loadingSummary = false);
    }
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

    return access.granted;
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

  Future<void> _startStream() async {
    if (_isSimulating) _stopSimulation();

    final granted = await _ensureLocationReady(requestIfDenied: true);
    if (!granted) {
      return;
    }

    _stopRealGps();
    setState(() {
      _streaming = true;
      _locationMode = 'Real GPS';
    });

    final currentPosition = await _gps.getCurrentPosition();
    if (currentPosition != null && _shouldAcceptGpsPosition(currentPosition)) {
      _handleRealGpsPosition(currentPosition);
    }

    _positionSub = _gps.positionStream().listen((pos) {
      if (!mounted) return;
      if (!_shouldAcceptGpsPosition(pos)) return;
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

    _startHeartbeat();
  }

  void _handleRealGpsPosition(Position pos) {
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _speedKmh = pos.speed * 3.6;
      _accuracyMeters = pos.accuracy;
      _locationMode = 'Real GPS';
      _addRoutePoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
        source: 'Real GPS',
      );
    });
    _sendLocation(pos);
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
      _lat = latitude;
      _lng = longitude;
      _speedKmh = speedKmh;
      _accuracyMeters = accuracyMeters;
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

  Future<void> _sendLocation(Position pos) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final res = await widget.api.sendLocationUpdate(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: pos.speed * 3.6,
        accuracyMeters: pos.accuracy,
        networkType: _networkType,
      );
      if (mounted) {
        setState(() {
          _pointsSent++;
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

  bool _shouldAcceptGpsPosition(Position pos) {
    if (pos.accuracy > _maxAcceptedGpsAccuracyMeters) {
      setState(() {
        _accuracyMeters = pos.accuracy;
        _lastServerMsg =
            'GPS kurang akurat (${pos.accuracy.toStringAsFixed(1)} m)';
      });
      return false;
    }

    if (_routePoints.isEmpty) return true;

    final last = _routePoints.last;
    final distance = _haversineMeters(
      last.latitude,
      last.longitude,
      pos.latitude,
      pos.longitude,
    );
    final seconds = DateTime.now().difference(last.recordedAt).inSeconds;
    final impliedSpeed = seconds <= 0 ? 0 : (distance / seconds) * 3.6;

    if (distance > 20 && impliedSpeed > _maxAcceptedJumpSpeedKmh) {
      setState(() {
        _lastServerMsg =
            'GPS loncat, titik diabaikan (${impliedSpeed.toStringAsFixed(1)} km/h)';
      });
      return false;
    }

    return true;
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
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Text('Dashboard Sepeda'),
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
          ? const Center(child: CircularProgressIndicator())
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
    final displaySpeed = _speedKmh ?? rental?.currentSpeedKmh ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadBike();
        await _loadRentalSummary();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBanner(
            streaming: _streaming,
            mode: _locationMode,
            sending: _sending,
            serverMessage: _lastServerMsg,
          ),
          if (_checkingLocationAccess || !_locationAccessGranted) ...[
            const SizedBox(height: 12),
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
          _BikeHeader(bike: bike),
          const SizedBox(height: 12),
          _SpeedDashboard(
            speedKmh: displaySpeed,
            accuracyMeters:
                _accuracyMeters ?? rental?.latestLocationPoint?.accuracyMeters,
            latitude: _lat ?? rental?.latestLocationPoint?.latitude,
            longitude: _lng ?? rental?.latestLocationPoint?.longitude,
            lastSentAt: _lastSentAt,
            routePoints: List.unmodifiable(_routePoints),
          ),
          const SizedBox(height: 12),
          _RentalDashboard(
            rental: rental,
            loading: _loadingSummary,
            now: _now,
          ),
          const SizedBox(height: 12),
          _DeviceGrid(
            batteryPercent: _batteryPercent,
            networkType: _networkType,
            pointsSent: _pointsSent,
            lastSentAt: _lastSentAt,
            locationMode: _locationMode,
            streaming: _streaming,
          ),
          const SizedBox(height: 12),
          _buildControls(),
          const SizedBox(height: 12),
          _buildDebugPanel(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _streaming ? _stopStream : _startStream,
            icon: Icon(
              _streaming ? Icons.stop_circle_outlined : Icons.gps_fixed_rounded,
            ),
            label: Text(
              _streaming ? 'Hentikan Pengiriman' : 'Mulai Kirim GPS Real',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _streaming
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0F766E),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _streaming ? _sendHeartbeat : null,
          icon: const Icon(Icons.favorite_rounded, size: 18),
          label: const Text('Kirim Heartbeat Manual'),
        ),
      ],
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
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel Kontrol Debug',
                      style: TextStyle(
                        color: Color(0xFF134E4A),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manual GPS dan Mock Route untuk demo/testing.',
                      style: TextStyle(color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Panel ini selalu tampil agar kontrol tambahan tidak terlewat. Untuk penggunaan nyata, tetap gunakan tombol Mulai Kirim GPS Real.',
                  style: TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ManualGpsPanel(
            onCoordinateSend: _sendManualCoordinate,
            onToggleSimulation: _toggleSimulation,
            isSimulating: _isSimulating,
            simulationProgress: _simulationProgress,
            currentInterval: _currentInterval,
            currentMode: _currentMode,
            onIntervalChanged: (v) => setState(() => _currentInterval = v),
            onModeChanged: (v) => setState(() => _currentMode = v),
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
  });

  final bool streaming;
  final String mode;
  final bool sending;
  final String serverMessage;

  @override
  Widget build(BuildContext context) {
    final color = streaming ? const Color(0xFF027A48) : const Color(0xFFB42318);

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
                  streaming ? 'Pengiriman GPS aktif' : 'Pengiriman berhenti',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Mode: $mode | Server: $serverMessage',
                  maxLines: 1,
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

class _BikeHeader extends StatelessWidget {
  const _BikeHeader({required this.bike});

  final Bike bike;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFCCFBF1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pedal_bike_rounded,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike.code,
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bike.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          _Badge(label: _statusLabel(bike.status)),
        ],
      ),
    );
  }
}

class _SpeedDashboard extends StatelessWidget {
  const _SpeedDashboard({
    required this.speedKmh,
    required this.accuracyMeters,
    required this.latitude,
    required this.longitude,
    required this.lastSentAt,
    required this.routePoints,
  });

  final double speedKmh;
  final double? accuracyMeters;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSentAt;
  final List<_RoutePoint> routePoints;

  @override
  Widget build(BuildContext context) {
    final speedPercent = (speedKmh / 40).clamp(0.0, 1.0);
    final gpsQuality = _gpsQualityLabel(accuracyMeters);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Kecepatan Real-Time',
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                speedKmh.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  height: .95,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 7),
                child: Text(
                  'km/h',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: speedPercent,
              backgroundColor: const Color(0xFFE4E7EC),
              color: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 14),
          _MiniRouteMap(
            points: routePoints,
            latestAccuracyMeters: accuracyMeters,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.gps_fixed,
                label: gpsQuality,
              ),
              _InfoPill(
                icon: Icons.my_location,
                label: latitude == null || longitude == null
                    ? 'Koordinat belum ada'
                    : '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
              ),
              _InfoPill(
                icon: Icons.update,
                label: lastSentAt == null
                    ? 'Belum terkirim'
                    : '${_timeDiff(lastSentAt!)} lalu',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniRouteMap extends StatelessWidget {
  const _MiniRouteMap({
    required this.points,
    required this.latestAccuracyMeters,
  });

  final List<_RoutePoint> points;
  final double? latestAccuracyMeters;

  @override
  Widget build(BuildContext context) {
    final pointCount = points.length;

    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniRoutePainter(points),
            ),
          ),
          Positioned(
            left: 12,
            top: 10,
            child: _MapChip(
              icon: Icons.route_outlined,
              label: pointCount == 0 ? 'Jalur belum ada' : '$pointCount titik',
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: _MapChip(
              icon: Icons.gps_fixed,
              label: latestAccuracyMeters == null
                  ? 'GPS -'
                  : '${latestAccuracyMeters!.toStringAsFixed(0)} m',
            ),
          ),
          if (pointCount < 2)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Jalur akan muncul setelah device mengirim beberapa titik GPS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const Positioned(
            left: 12,
            bottom: 10,
            child: Row(
              children: [
                _LegendDot(color: Color(0xFF38BDF8)),
                SizedBox(width: 5),
                Text(
                  'Awal',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                ),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFF22C55E)),
                SizedBox(width: 5),
                Text(
                  'Terbaru',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  const _MiniRoutePainter(this.points);

  final List<_RoutePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1;

    const gridStep = 28.0;
    for (var x = 0.0; x <= size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final projected = _projectPoints(size);
    if (projected.isEmpty) return;

    if (projected.length >= 2) {
      final glowPaint = Paint()
        ..color = const Color(0x6638BDF8)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final routePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF22C55E)],
        ).createShader(Offset.zero & size)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(projected.first.dx, projected.first.dy);
      for (final point in projected.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, routePaint);
    }

    final start = projected.first;
    final latest = projected.last;
    _drawPoint(canvas, start, const Color(0xFF38BDF8), 5);
    _drawPoint(canvas, latest, const Color(0xFF22C55E), 7);

    final latestAccuracy = points.last.accuracyMeters;
    if (latestAccuracy > 0) {
      final radius = latestAccuracy.clamp(8, 32).toDouble();
      final accuracyPaint = Paint()
        ..color = const Color(0x3322C55E)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(latest, radius, accuracyPaint);
    }
  }

  List<Offset> _projectPoints(Size size) {
    final minLat = points.map((p) => p.latitude).reduce(math.min);
    final maxLat = points.map((p) => p.latitude).reduce(math.max);
    final minLng = points.map((p) => p.longitude).reduce(math.min);
    final maxLng = points.map((p) => p.longitude).reduce(math.max);

    final latSpan = math.max(maxLat - minLat, 0.00001);
    final lngSpan = math.max(maxLng - minLng, 0.00001);
    const padding = 24.0;
    final drawableWidth = math.max(size.width - (padding * 2), 1);
    final drawableHeight = math.max(size.height - (padding * 2), 1);

    return points.map((point) {
      final x =
          padding + ((point.longitude - minLng) / lngSpan) * drawableWidth;
      final y =
          padding + ((maxLat - point.latitude) / latSpan) * drawableHeight;
      return Offset(x, y);
    }).toList();
  }

  void _drawPoint(Canvas canvas, Offset offset, Color color, double radius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: .25)
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(offset.translate(0, 2), radius + 2, shadowPaint);
    canvas.drawCircle(offset, radius, fillPaint);
    canvas.drawCircle(offset, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) {
    return oldDelegate.points != points;
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

class _RentalDashboard extends StatelessWidget {
  const _RentalDashboard({
    required this.rental,
    required this.loading,
    required this.now,
  });

  final ActiveBikeRental? rental;
  final bool loading;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (loading && rental == null) {
      return const _Panel(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (rental == null) {
      return const _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Aktif',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada rental aktif untuk sepeda ini. Dashboard tetap bisa mengirim heartbeat dan lokasi untuk monitoring admin.',
              style: TextStyle(color: Color(0xFF667085)),
            ),
          ],
        ),
      );
    }

    final activeRental = rental!;
    final duration = activeRental.startedAt == null
        ? Duration.zero
        : now.difference(activeRental.startedAt!);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ringkasan Rental Aktif',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              _Badge(label: _rentalStatusLabel(activeRental.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activeRental.user == null
                ? 'Penyewa tidak tersedia'
                : 'Penyewa: ${activeRental.user!.name}',
            style: const TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 14),
          _MetricWrap(
            children: [
              _MetricTile(
                label: 'Durasi',
                value: _formatDuration(duration),
                icon: Icons.timer_outlined,
              ),
              _MetricTile(
                label: 'Total Jarak',
                value:
                    '${activeRental.totalDistanceKilometers.toStringAsFixed(2)} km',
                icon: Icons.route_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CostRow(
            distanceCost: activeRental.distanceCost,
            idleCost: activeRental.idleCost,
            totalCost: activeRental.totalCost,
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.distanceCost,
    required this.idleCost,
    required this.totalCost,
  });

  final int distanceCost;
  final int idleCost;
  final int totalCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CostItem(
              label: 'Jarak',
              value: _formatRupiah(distanceCost),
              icon: Icons.payments_outlined,
            ),
          ),
          _CostDivider(),
          Expanded(
            child: _CostItem(
              label: 'Idle',
              value: _formatRupiah(idleCost),
              icon: Icons.hourglass_bottom,
            ),
          ),
          _CostDivider(),
          Expanded(
            child: _CostItem(
              label: 'Total',
              value: _formatRupiah(totalCost),
              icon: Icons.receipt_long,
              emphasized: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  const _CostItem({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color =
        emphasized ? const Color(0xFF0F766E) : const Color(0xFF475467);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: emphasized
                  ? const Color(0xFF134E4A)
                  : const Color(0xFF101828),
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CostDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFCCFBF1),
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({
    required this.batteryPercent,
    required this.networkType,
    required this.pointsSent,
    required this.lastSentAt,
    required this.locationMode,
    required this.streaming,
  });

  final int batteryPercent;
  final String networkType;
  final int pointsSent;
  final DateTime? lastSentAt;
  final String locationMode;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    return _MetricWrap(
      children: [
        _MetricTile(
          label: 'Baterai',
          value: '$batteryPercent%',
          icon: Icons.battery_charging_full,
          emphasized: batteryPercent <= 20,
        ),
        _MetricTile(
          label: 'Jaringan',
          value: networkType,
          icon: Icons.network_cell_outlined,
        ),
        _MetricTile(
          label: 'Titik Terkirim',
          value: '$pointsSent',
          icon: Icons.upload_rounded,
        ),
        _MetricTile(
          label: 'Terakhir Kirim',
          value: lastSentAt == null ? '-' : '${_timeDiff(lastSentAt!)} lalu',
          icon: Icons.update,
        ),
        _MetricTile(
          label: 'Mode Lokasi',
          value: locationMode,
          icon: Icons.explore_outlined,
        ),
        _MetricTile(
          label: 'Status Device',
          value: streaming ? 'Aktif' : 'Standby',
          icon: Icons.sensors,
        ),
      ],
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 3 ? 1.7 : 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(12),
      borderColor: emphasized ? const Color(0xFF5EEAD4) : null,
      backgroundColor: emphasized ? const Color(0xFFF0FDFA) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                emphasized ? const Color(0xFF0F766E) : const Color(0xFF667085),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF101828),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFABEFC6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF027A48),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475467)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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

String _formatDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours;
  final minutes = safeDuration.inMinutes.remainder(60);
  final seconds = safeDuration.inSeconds.remainder(60);

  if (hours > 0) {
    return [
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');
  }

  return [
    minutes.toString().padLeft(2, '0'),
    seconds.toString().padLeft(2, '0'),
  ].join(':');
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
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  return '${diff.inHours}j';
}

String _gpsQualityLabel(double? accuracyMeters) {
  if (accuracyMeters == null) return 'GPS belum tersedia';
  if (accuracyMeters <= 10) return 'GPS sangat akurat';
  if (accuracyMeters <= 25) return 'GPS akurat';
  if (accuracyMeters <= 50) return 'GPS sedang';
  return 'GPS kurang akurat';
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

String _statusLabel(String status) {
  return switch (status) {
    'available' => 'Tersedia',
    'reserved' => 'Dipesan',
    'in_use' => 'Dipakai',
    'idle' => 'Diam',
    'offline' => 'Offline',
    'maintenance' => 'Perawatan',
    _ => status,
  };
}

String _rentalStatusLabel(String status) {
  return switch (status) {
    'active' => 'Aktif',
    'idle_warning' => 'Peringatan Diam',
    'idle_billing' => 'Biaya Diam',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}
