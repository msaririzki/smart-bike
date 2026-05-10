import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/bike.dart';
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
  final _gps = GpsService();
  final _battery = Battery();

  Bike? _bike;
  bool _loadingBike = true;

  // Stream state
  bool _streaming = false;
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatTimer;

  // Live data
  double? _lat;
  double? _lng;
  double? _speedKmh;
  double? _accuracyMeters;
  String _networkType = 'unknown';
  int _batteryPercent = 0;
  int _pointsSent = 0;
  DateTime? _lastSentAt;
  String _lastServerMsg = '—';
  bool _sending = false;

  // Mock & Manual GPS state
  final _mockService = MockRouteService();
  Timer? _mockTimer;
  bool _isSimulating = false;
  String _simulationProgress = '';

  @override
  void initState() {
    super.initState();
    _loadBike();
    _listenNetwork();
    _loadBattery();
  }

  @override
  void dispose() {
    _stopStream();
    _stopSimulation();
    super.dispose();
  }

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> _loadBike() async {
    try {
      final bike = await widget.api.currentAssignment();
      if (mounted) setState(() => _bike = bike);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal load assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBike = false);
    }
  }

  void _listenNetwork() {
    Connectivity().onConnectivityChanged.listen((results) {
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
      // Refresh baterai tiap 60 detik
      Timer.periodic(const Duration(seconds: 60), (_) async {
        if (!mounted) return;
        final l = await _battery.batteryLevel;
        if (mounted) setState(() => _batteryPercent = l);
      });
    } catch (_) {}
  }

  String _connectivityLabel(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile)) return '4G/3G';
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'Offline';
  }

  // ─── Stream Control ──────────────────────────────────────────────────────

  Future<void> _startStream() async {
    final granted = await _gps.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin GPS diperlukan untuk streaming.')),
        );
      }
      return;
    }

    setState(() => _streaming = true);

    // GPS stream
    _positionSub = _gps.positionStream(intervalSeconds: 5).listen((pos) {
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _speedKmh = pos.speed * 3.6; // m/s → km/h
        _accuracyMeters = pos.accuracy;
      });
      _sendLocation(pos);
    });

    // Heartbeat tiap 30 detik
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
    // Kirim heartbeat pertama langsung
    _sendHeartbeat();
  }

  void _stopStream() {
    _positionSub?.cancel();
    _positionSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (mounted) setState(() => _streaming = false);
  }

  // ─── Mock / Manual Control ───────────────────────────────────────────────

  void _sendManualCoordinate(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _speedKmh = 0; // Manual static point
      _accuracyMeters = 0;
    });
    
    // We create a dummy Position object for the existing _sendLocation method
    final pos = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    
    _sendLocation(pos);
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    // If streaming real GPS, stop it first
    if (_streaming) _stopStream();

    _mockService.reset();
    setState(() {
      _isSimulating = true;
      _streaming = true; // Mark as streaming for the UI status badge
      _updateSimulationProgress();
    });

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final point = _mockService.currentPoint;
      _sendManualCoordinate(point.latitude, point.longitude);
      
      if (_mockService.hasNext) {
        _mockService.next();
        if (mounted) {
          setState(() => _updateSimulationProgress());
        }
      } else {
        _mockService.reset(); // Loop or stop? Instructions say "Simulasi Rute: Titik 3/10", usually implies loop or just keep going
        if (mounted) {
          setState(() => _updateSimulationProgress());
        }
      }
    });

    // Send first point immediately
    final firstPoint = _mockService.currentPoint;
    _sendManualCoordinate(firstPoint.latitude, firstPoint.longitude);
  }

  void _stopSimulation() {
    _mockTimer?.cancel();
    _mockTimer = null;
    if (mounted) {
      setState(() {
        _isSimulating = false;
        _streaming = false;
        _simulationProgress = '';
      });
    }
  }

  void _updateSimulationProgress() {
    _simulationProgress = 'Simulasi Rute: Titik ${_mockService.currentIndex + 1}/${_mockService.totalPoints}';
  }

  // ─── API Calls ───────────────────────────────────────────────────────────

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
          _lastServerMsg = res['message']?.toString() ?? '✓ OK';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _lastServerMsg = '⚠ $e');
    } finally {
      if (mounted) setState(() => _sending = false);
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

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Bike Simulator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBike,
            tooltip: 'Refresh Assignment',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loadingBike
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            )
          : _bike == null
              ? _buildNoBikeView()
              : _buildSimulatorView(),
    );
  }

  Widget _buildNoBikeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pedal_bike_rounded,
                size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada sepeda\nyang di-assign ke akun ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hubungi admin untuk assign sepeda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadBike,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status badge
          _buildStatusCard(),
          const SizedBox(height: 12),
          // Bike info
          _buildBikeCard(),
          const SizedBox(height: 12),
          // Manual & Mock Control
          ManualGpsPanel(
            onCoordinateSend: _sendManualCoordinate,
            onToggleSimulation: _toggleSimulation,
            isSimulating: _isSimulating,
            simulationProgress: _simulationProgress,
          ),
          const SizedBox(height: 12),
          // GPS & Sensor data
          _buildSensorCard(),
          const SizedBox(height: 12),
          // Stats
          _buildStatsCard(),
          const SizedBox(height: 24),
          // Controls
          _buildControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _streaming
            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _streaming
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Blinking dot
          _AnimatedDot(active: _streaming),
          const SizedBox(width: 12),
          Text(
            _streaming ? 'STREAMING AKTIF' : 'STREAM BERHENTI',
            style: TextStyle(
              color: _streaming
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (_sending)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF22C55E),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBikeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🚲 Sepeda Assigned'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                ),
                child: Text(
                  _bike!.code,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _bike!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('Status', _bike!.status.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildSensorCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📡 Data Sensor Real-Time'),
          const SizedBox(height: 12),
          _row('Latitude', _lat != null ? _lat!.toStringAsFixed(7) : '—'),
          _row('Longitude', _lng != null ? _lng!.toStringAsFixed(7) : '—'),
          _row('Kecepatan',
              _speedKmh != null ? '${_speedKmh!.toStringAsFixed(1)} km/h' : '—'),
          _row('Akurasi GPS',
              _accuracyMeters != null ? '${_accuracyMeters!.toStringAsFixed(1)} m' : '—'),
          _divider(),
          _row('Jaringan', _networkType),
          _row('Baterai', '$_batteryPercent%'),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📤 Statistik Pengiriman'),
          const SizedBox(height: 12),
          _row('Titik Terkirim', '$_pointsSent'),
          _row(
            'Terakhir Kirim',
            _lastSentAt != null
                ? _timeDiff(_lastSentAt!)
                : '—',
          ),
          _divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Server: ',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              Expanded(
                child: Text(
                  _lastServerMsg,
                  style: TextStyle(
                    color: _lastServerMsg.startsWith('⚠')
                        ? Colors.orange
                        : const Color(0xFF22C55E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Start / Stop
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _streaming ? _stopStream : _startStream,
            icon: Icon(_streaming
                ? Icons.stop_circle_rounded
                : Icons.play_circle_filled_rounded),
            label: Text(
              _streaming ? 'Stop Stream' : 'Mulai Stream GPS',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _streaming ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Manual Heartbeat
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _streaming ? _sendHeartbeat : null,
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Kirim Heartbeat Manual'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
              side: const BorderSide(color: Color(0xFF334155)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: child,
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace')),
          ],
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Color(0xFF334155), height: 1),
      );

  String _timeDiff(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    return '${diff.inHours}j lalu';
  }
}

// ─── Animated blinking dot ────────────────────────────────────────────────────

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({required this.active});
  final bool active;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + (_ctrl.value * 0.6),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
