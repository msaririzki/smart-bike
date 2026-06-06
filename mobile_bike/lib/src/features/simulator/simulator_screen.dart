import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/bike.dart';
import '../../models/cell_info_snapshot.dart';
import '../../models/device_rental_summary.dart';
import '../../services/api_client.dart';
import '../../services/cell_info_service.dart';
import '../../services/gps_service.dart';
import '../../services/session_store.dart';

import 'device_details_screen.dart';
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

class _SimulatorScreenState extends State<SimulatorScreen>
    with SingleTickerProviderStateMixin {
  static const double _maxAcceptedGpsAccuracyMeters = 50;
  static const double _defaultMaxBillableSpeedKmh = 40;
  static const double _maxAcceptedJumpSpeedKmh = 80;
  static const double _minRouteDistanceMeters = 1.5;
  static const double _maxDynamicMovementThresholdMeters = 35;
  static const double _minReliableSpeedKmh = 2;
  static const Duration _gpsWarmupDuration = Duration(seconds: 6);
  static const int _gpsWarmupMinSamples = 3;
  static const double _speedRiseLimitKmhPerSecond = 5;
  static const double _speedFallLimitKmhPerSecond = 8;
  static const Duration _stationaryServerPingInterval = Duration(seconds: 15);
  static const Duration _autoFollowReturnDelay = Duration(seconds: 10);
  static const int _maxRoutePoints = 3000;

  final _gps = GpsService();
  final _battery = Battery();
  final _cellInfo = CellInfoService();

  Bike? _bike;
  DeviceRentalSummary? _summary;
  bool _loadingBike = true;

  bool _streaming = false;

  bool _sending = false;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<List<ConnectivityResult>>? _networkSub;
  Timer? _heartbeatTimer;
  Timer? _batteryTimer;
  Timer? _summaryTimer;
  Timer? _clockTimer;

  Timer? _realGpsRefreshTimer;
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  double? _speedKmh;
  double? _accuracyMeters;
  String _networkType = 'unknown';
  int _batteryPercent = 0;
  DateTime? _lastGpsReadAt;
  DateTime? _lastSentAt;
  DateTime _now = DateTime.now();
  int? _activeRentalId;
  String _lastServerMsg = 'Belum ada pengiriman';
  CellInfoSnapshot? _currentCell;
  String? _lastCellKey;
  bool _recordCellSurvey = false;
  String _lastCellEvent = 'Perekaman BTS nonaktif';

  String _locationMode = 'Belum aktif';
  bool _checkingLocationAccess = true;
  bool _locationAccessGranted = false;
  bool _autoStartAttempted = false;
  bool _idleDialogOpen = false;
  String? _lastIdleAlertKey;
  DateTime? _lastOverspeedAlertAt;
  LocationAccessStatus _locationAccessStatus = LocationAccessStatus.denied;
  String _locationAccessMessage = 'Mengecek akses lokasi perangkat...';
  double _maxBillableSpeedKmh = _defaultMaxBillableSpeedKmh;
  final List<_RoutePoint> _routePoints = [];
  _RoutePoint? _lastAcceptedGpsPoint;
  _PendingLocationUpdate? _pendingLocationUpdate;
  DateTime? _lastStationarySentAt;
  DateTime? _lastServerRecordedAt;
  DateTime? _gpsWarmupStartedAt;
  DateTime? _lastSpeedSampleAt;
  int _gpsWarmupSampleCount = 0;
  bool _gpsWarmupComplete = false;
  double _smoothedSpeedKmh = 0;
  double? _compassHeadingDegrees;
  DateTime? _lastCompassAt;
  double? _headingDegrees;
  _BikeMapType _mapType = _BikeMapType.standard;
  _MapFollowMode _followMode = _MapFollowMode.auto;
  bool _mapControlsExpanded = false;
  DateTime? _autoFollowReturnAt;
  int? _autoFollowReturnSeconds;
  Timer? _autoFollowReturnTimer;
  Timer? _autoFollowCountdownTimer;
  final MapController _mapController = MapController();
  final ValueNotifier<int> _monitoringPanelRevision = ValueNotifier<int>(0);

  bool get _hasActiveRental => _summary?.rental != null;
  bool get _isGpsWarmupActive =>
      _hasActiveRental && !_gpsWarmupComplete && _gpsWarmupStartedAt != null;

  @override
  void initState() {
    super.initState();
    unawaited(_enableWakeLock());
    _loadBike();
    _loadRentalSummary();
    _ensureLocationReady(requestIfDenied: true, showMessage: false);
    _listenCompass();
    _listenNetwork();
    _loadBattery();
    _summaryTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadRentalSummary(silent: true),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        _refreshMonitoringPanel();
      }
    });
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _stopStream();
    unawaited(_disableWakeLock());
    _compassSub?.cancel();
    _networkSub?.cancel();
    _batteryTimer?.cancel();
    _summaryTimer?.cancel();
    _clockTimer?.cancel();
    _autoFollowReturnTimer?.cancel();
    _autoFollowCountdownTimer?.cancel();
    _refreshController.dispose();
    _mapController.dispose();
    _monitoringPanelRevision.dispose();
    super.dispose();
  }

  void _refreshMonitoringPanel() {
    _monitoringPanelRevision.value++;
  }

  void _setStateAndRefreshMonitoring(VoidCallback update) {
    if (!mounted) return;
    setState(update);
    _refreshMonitoringPanel();
  }

  Future<void> _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Browser preview can reject Wake Lock permission; tracking should continue.
    }
  }

  Future<void> _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  void _listenCompass() {
    final events = FlutterCompass.events;
    if (events == null) return;

    _compassSub = events.listen(
      (event) {
        final heading = _normalizeHeading(
          event.headingForCameraMode ?? event.heading,
        );
        if (heading == null || !mounted) return;

        final now = DateTime.now();
        final lastCompassAt = _lastCompassAt;
        if (lastCompassAt != null &&
            now.difference(lastCompassAt) < const Duration(milliseconds: 250)) {
          return;
        }

        setState(() {
          _lastCompassAt = now;
          _compassHeadingDegrees = _smoothHeading(
            _compassHeadingDegrees,
            heading,
            .3,
          );

          final speed = _speedKmh ?? 0;
          if (_headingDegrees == null || speed < _minReliableSpeedKmh) {
            _headingDegrees = _smoothHeading(
              _headingDegrees,
              _compassHeadingDegrees!,
              .35,
            );
          }
        });

        if (_followMode == _MapFollowMode.auto && _routePoints.isNotEmpty) {
          _rotateMapToHeading();
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _loadBike() async {
    try {
      final bike = await widget.api.currentAssignment();
      if (mounted) _setStateAndRefreshMonitoring(() => _bike = bike);
      _autoStartRealGpsIfReady();
    } catch (e) {
      _showMessage('Gagal memuat sepeda: $e');
    } finally {
      if (mounted) _setStateAndRefreshMonitoring(() => _loadingBike = false);
    }
  }

  Future<void> _loadRentalSummary({bool silent = false}) async {
    try {
      final summary = await widget.api.activeRentalSummary();
      if (!mounted) return;
      _setStateAndRefreshMonitoring(() {
        _summary = summary;
        _bike = summary.bike ?? _bike;
        final maxReasonableSpeedKmh = summary.settings?.maxReasonableSpeedKmh;
        _maxBillableSpeedKmh =
            maxReasonableSpeedKmh != null && maxReasonableSpeedKmh > 0
                ? maxReasonableSpeedKmh
                : _defaultMaxBillableSpeedKmh;
        final nextRentalId = summary.rental?.id;
        if (nextRentalId != _activeRentalId) {
          _resetRealtimeTrackingState();
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
    if (!mounted) return;
    _idleDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isBilling = rental.status == 'idle_billing';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 32),
                    // Premium Warning Icon with Gradient
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB267), Color(0xFFFF7E3A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7E3A).withValues(alpha: .4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Sepeda Diam!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    isBilling
                        ? 'Sepeda Anda terdeteksi diam terlalu lama dan biaya idle sudah aktif.'
                        : 'Sepeda Anda tidak bergerak selama beberapa menit terakhir.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Information Panel (Yellow Box)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isBilling
                                    ? 'Biaya idle sedang berjalan. Total: ${_formatRupiah(rental.idleCost)}. Harap segera lanjutkan perjalanan untuk menghentikan denda.'
                                    : 'Pilih lanjut jika masih memakai sepeda. Jika tetap diam, biaya idle akan segera berjalan.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Fee Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAF0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.attach_money_rounded,
                                  color: Color(0xFFD97706), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tarif idle: Rp200 per 5 menit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                    const SizedBox(height: 32),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _idleDialogOpen = false;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => _idleDialogOpen = false);
  }

  void _listenNetwork() {
    _networkSub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      _setStateAndRefreshMonitoring(
        () => _networkType = _connectivityLabel(results),
      );
    });
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        _setStateAndRefreshMonitoring(
          () => _networkType = _connectivityLabel(results),
        );
      }
    });
  }

  Future<void> _loadBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) _setStateAndRefreshMonitoring(() => _batteryPercent = level);
      _batteryTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
        final nextLevel = await _battery.batteryLevel;
        if (mounted) {
          _setStateAndRefreshMonitoring(() => _batteryPercent = nextLevel);
        }
      });
    } catch (_) {
      if (mounted) _setStateAndRefreshMonitoring(() => _batteryPercent = 0);
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
    if (mounted) {
      _setStateAndRefreshMonitoring(() => _checkingLocationAccess = true);
    }

    final access = await _gps.ensureLocationAccess(
      requestIfDenied: requestIfDenied,
    );
    final message = _locationAccessText(access.status);

    if (!mounted) return access.granted;
    _setStateAndRefreshMonitoring(() {
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
    if (_streaming) return;

    _autoStartAttempted = true;
    _startStream(requestPermission: false);
  }

  Future<void> _openLocationSettings() async {
    try {
      if (_locationAccessStatus == LocationAccessStatus.deniedForever) {
        await Geolocator.openAppSettings();
      } else {
        await Geolocator.openLocationSettings();
      }
    } catch (_) {
      _showMessage('Pengaturan lokasi tidak tersedia di platform ini.');
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
    final granted = requestPermission
        ? await _ensureLocationReady(requestIfDenied: true)
        : _locationAccessGranted;
    if (!granted) {
      return;
    }

    _stopRealGps();
    _setStateAndRefreshMonitoring(() {
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
      _setStateAndRefreshMonitoring(() {
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
      GpsService.trackingInterval,
      (_) => _refreshRealGpsPosition(),
    );
  }

  Future<void> _refreshRealGpsPosition() async {
    if (!_streaming) return;

    final currentPosition = await _gps.getCurrentPosition();
    if (!mounted || currentPosition == null) return;

    _handleRealGpsPosition(currentPosition);
  }

  void _handleRealGpsPosition(Position pos) {
    final sampledAt = _effectiveGpsSampleTime(pos);
    final rentalActive = _hasActiveRental;

    _setStateAndRefreshMonitoring(() {
      _accuracyMeters = pos.accuracy;
      _lastGpsReadAt = sampledAt;
      _locationMode = 'Real GPS';
    });

    if (pos.accuracy > _maxAcceptedGpsAccuracyMeters) {
      _setStateAndRefreshMonitoring(() {
        _speedKmh = 0;
        _lastServerMsg =
            'GPS kurang akurat (${pos.accuracy.toStringAsFixed(1)} m), titik diabaikan';
      });
      return;
    }

    if (!rentalActive) {
      _resetSpeedSmoothing();
      _setStateAndRefreshMonitoring(() => _speedKmh = 0);
      _sendLocation(pos, speedKmh: 0);
      return;
    }

    _startGpsWarmupIfNeeded(sampledAt);
    _gpsWarmupSampleCount++;

    final previous = _lastAcceptedGpsPoint;
    if (previous == null) {
      _acceptRealGpsPoint(
        pos,
        sampledAt: sampledAt,
        speedKmh: 0,
        serverSpeedKmh: 0,
        distance: 0,
        message: 'Mengunci GPS awal.',
      );
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
    final targetSpeedKmh = _targetDisplaySpeedKmh(pos, impliedSpeedKmh);
    final clearMovement = distance >= movementThreshold &&
        impliedSpeedKmh >= _minReliableSpeedKmh &&
        impliedSpeedKmh <= _maxAcceptedJumpSpeedKmh;
    final warmupReady = _updateGpsWarmupState(sampledAt, clearMovement);
    final displaySpeedKmh =
        warmupReady ? _smoothDisplaySpeed(targetSpeedKmh, sampledAt) : 0.0;

    _setStateAndRefreshMonitoring(() => _speedKmh = displaySpeedKmh);

    if (!warmupReady) {
      _setStateAndRefreshMonitoring(() {
        _lastServerMsg =
            'Mengunci GPS awal (${_gpsWarmupSampleCount.clamp(1, _gpsWarmupMinSamples)}/$_gpsWarmupMinSamples)';
      });
      if (distance < movementThreshold) {
        _sendStationaryPingIfDue(previous, pos);
      }
      return;
    }

    if (distance < movementThreshold) {
      _setStateAndRefreshMonitoring(() {
        if (displaySpeedKmh < _minReliableSpeedKmh) {
          _speedKmh = 0;
        }
        _lastServerMsg =
            'GPS stabil: perpindahan ${distance.toStringAsFixed(1)} m dianggap diam';
      });
      _sendStationaryPingIfDue(previous, pos);
      return;
    }

    final validationSpeedKmh =
        targetSpeedKmh >= _minReliableSpeedKmh ? targetSpeedKmh : impliedSpeedKmh;

    if (validationSpeedKmh > _maxBillableSpeedKmh) {
      final anomalySpeedKmh = validationSpeedKmh;
      final displayAnomalySpeedKmh =
          anomalySpeedKmh.clamp(0.0, _maxAcceptedJumpSpeedKmh).toDouble();

      _acceptRealGpsPoint(
        pos,
        sampledAt: sampledAt,
        speedKmh: displayAnomalySpeedKmh,
        serverSpeedKmh: anomalySpeedKmh,
        distance: distance,
        isSpeedAnomaly: true,
        message:
            'Melebihi batas ${_maxBillableSpeedKmh.toStringAsFixed(0)} km/h; segmen ditandai merah.',
      );
      _showOverspeedAlert(anomalySpeedKmh);
      return;
    }

    _acceptRealGpsPoint(
      pos,
      sampledAt: sampledAt,
      speedKmh: displaySpeedKmh,
      serverSpeedKmh: targetSpeedKmh,
      distance: distance,
      message: 'GPS valid, pergerakan ${distance.toStringAsFixed(1)} m.',
    );
  }

  void _stopStream() {
    _stopRealGps();
    _stopHeartbeat();
    if (mounted) {
      _setStateAndRefreshMonitoring(() {
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
    _pendingLocationUpdate = null;
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

  double _targetDisplaySpeedKmh(Position pos, double impliedSpeedKmh) {
    final gpsSpeedKmh =
        pos.speed.isFinite && pos.speed > 0 ? pos.speed * 3.6 : 0.0;
    final gpsReliable = gpsSpeedKmh >= _minReliableSpeedKmh &&
        gpsSpeedKmh <= _maxAcceptedJumpSpeedKmh;
    final impliedReliable = impliedSpeedKmh >= _minReliableSpeedKmh &&
        impliedSpeedKmh <= _maxAcceptedJumpSpeedKmh;

    if (gpsReliable && impliedReliable) {
      final delta = (gpsSpeedKmh - impliedSpeedKmh).abs();
      if (delta <= 10) {
        return (gpsSpeedKmh * .65) + (impliedSpeedKmh * .35);
      }
      return gpsSpeedKmh;
    }

    if (gpsReliable) return gpsSpeedKmh;
    if (impliedReliable) return impliedSpeedKmh;
    return 0;
  }

  double _smoothDisplaySpeed(double targetSpeedKmh, DateTime sampledAt) {
    final target = targetSpeedKmh < _minReliableSpeedKmh ? 0.0 : targetSpeedKmh;
    final previous = _smoothedSpeedKmh;
    final lastSampleAt = _lastSpeedSampleAt;
    final seconds = lastSampleAt == null
        ? GpsService.trackingInterval.inMilliseconds /
            Duration.millisecondsPerSecond
        : math.max(
            sampledAt.difference(lastSampleAt).inMilliseconds /
                Duration.millisecondsPerSecond,
            .2,
          );
    final alpha = target >= previous ? .55 : .72;
    final blended = previous + ((target - previous) * alpha);
    final maxDelta = (target >= previous
            ? _speedRiseLimitKmhPerSecond
            : _speedFallLimitKmhPerSecond) *
        seconds;
    final limited = previous + (blended - previous).clamp(-maxDelta, maxDelta);
    final next = limited < .8 ? 0.0 : limited;

    _smoothedSpeedKmh = next;
    _lastSpeedSampleAt = sampledAt;

    return next;
  }

  void _startGpsWarmupIfNeeded(DateTime sampledAt) {
    _gpsWarmupStartedAt ??= sampledAt;
  }

  bool _updateGpsWarmupState(DateTime sampledAt, bool clearMovement) {
    if (_gpsWarmupComplete) return true;

    if (clearMovement && _gpsWarmupSampleCount >= 2) {
      _gpsWarmupComplete = true;
      return true;
    }

    final startedAt = _gpsWarmupStartedAt ?? sampledAt;
    final enoughSamples = _gpsWarmupSampleCount >= _gpsWarmupMinSamples;
    final enoughTime = sampledAt.difference(startedAt) >= _gpsWarmupDuration;

    if (enoughSamples && enoughTime) {
      _gpsWarmupComplete = true;
      return true;
    }

    return false;
  }

  void _resetSpeedSmoothing() {
    _smoothedSpeedKmh = 0;
    _lastSpeedSampleAt = null;
  }

  void _resetRealtimeTrackingState() {
    _routePoints.clear();
    _lastAcceptedGpsPoint = null;
    _pendingLocationUpdate = null;
    _lastStationarySentAt = null;
    _lastServerRecordedAt = null;
    _gpsWarmupStartedAt = null;
    _gpsWarmupSampleCount = 0;
    _gpsWarmupComplete = false;
    _headingDegrees = null;
    _compassHeadingDegrees = null;
    _lastCompassAt = null;
    _resetSpeedSmoothing();
    _speedKmh = 0;
  }

  DateTime _effectiveGpsSampleTime(Position pos) {
    final now = DateTime.now();
    final gpsTime = pos.timestamp.toLocal();
    final tooOld = now.difference(gpsTime).abs() > const Duration(seconds: 10);

    if (tooOld || gpsTime.isAfter(now.add(const Duration(seconds: 2)))) {
      return now;
    }

    return gpsTime;
  }

  DateTime _nextServerRecordedAt(DateTime candidate) {
    final last = _lastServerRecordedAt;
    if (last != null && !candidate.isAfter(last)) {
      candidate = last.add(const Duration(milliseconds: 1));
    }

    _lastServerRecordedAt = candidate;
    return candidate;
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
    required DateTime sampledAt,
    required double speedKmh,
    required double serverSpeedKmh,
    required String message,
    double distance = 0,
    bool isSpeedAnomaly = false,
  }) {
    final previous = _lastAcceptedGpsPoint;
    final headingDegrees = _headingFromPosition(pos, previous);
    final point = _RoutePoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      recordedAt: sampledAt,
      headingDegrees: headingDegrees ?? previous?.headingDegrees,
      isSpeedAnomaly: isSpeedAnomaly,
    );

    _lastAcceptedGpsPoint = point;
    _lastStationarySentAt = null;

    _setStateAndRefreshMonitoring(() {
      _speedKmh = speedKmh;
      if (point.headingDegrees != null) {
        _headingDegrees = _smoothHeading(
          _headingDegrees,
          point.headingDegrees!,
          .45,
        );
      }
      _lastServerMsg = message;
      _addRoutePoint(
        latitude: point.latitude,
        longitude: point.longitude,
        accuracyMeters: point.accuracyMeters,
        headingDegrees: _headingDegrees ?? point.headingDegrees,
        isSpeedAnomaly: point.isSpeedAnomaly,
      );
    });
    _updateMapCamera();

    _sendLocation(pos, speedKmh: serverSpeedKmh);
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

  Future<void> _sendLocation(
    Position pos, {
    double? speedKmh,
    DateTime? recordedAt,
  }) async {
    final effectiveRecordedAt = _nextServerRecordedAt(
      recordedAt ?? _effectiveGpsSampleTime(pos),
    );

    if (_sending) {
      _pendingLocationUpdate = _PendingLocationUpdate(
        position: pos,
        speedKmh: speedKmh,
        recordedAt: effectiveRecordedAt,
      );
      return;
    }

    _setStateAndRefreshMonitoring(() => _sending = true);
    try {
      final cell = _streaming && _recordCellSurvey
          ? await _cellInfo.currentServingCell()
          : null;
      _updateCellStatus(cell);
      final res = await widget.api.sendLocationUpdate(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: speedKmh ?? (pos.speed * 3.6),
        accuracyMeters: pos.accuracy,
        networkType: _networkType,
        recordedAt: effectiveRecordedAt,
        cell: cell,
      );
      if (mounted) {
        _setStateAndRefreshMonitoring(() {
          _lastSentAt = DateTime.now();
          _lastServerMsg = res['message']?.toString() ?? 'OK';
        });
        _loadRentalSummary(silent: true);
      }
    } catch (e) {
      if (mounted) {
        _setStateAndRefreshMonitoring(() => _lastServerMsg = 'Error: $e');
      }
    } finally {
      if (mounted) _setStateAndRefreshMonitoring(() => _sending = false);
      final pending = _pendingLocationUpdate;
      if (pending != null && mounted) {
        _pendingLocationUpdate = null;
        unawaited(
          _sendLocation(
            pending.position,
            speedKmh: pending.speedKmh,
            recordedAt: pending.recordedAt,
          ),
        );
      }
    }
  }

  void _updateCellStatus(CellInfoSnapshot? cell) {
    if (!mounted || cell == null) return;

    final previousKey = _lastCellKey;
    final nextKey = cell.identityKey;

    _setStateAndRefreshMonitoring(() {
      _currentCell = cell;
      if (nextKey != null) {
        _lastCellKey = nextKey;
      }
      _lastCellEvent =
          previousKey != null && nextKey != null && previousKey != nextKey
          ? 'Pindah BTS/Cell: ${cell.shortLabel}'
          : 'BTS aktif: ${cell.shortLabel}';
    });

    if (previousKey != null && nextKey != null && previousKey != nextKey) {
      _showMessage('Pindah BTS/Cell: ${cell.shortLabel}');
    }
  }

  void _setCellSurveyRecording(bool value) {
    _setStateAndRefreshMonitoring(() {
      _recordCellSurvey = value;
      if (value) {
        _lastCellEvent = 'Mengecek BTS aktif';
      } else {
        _currentCell = null;
        _lastCellKey = null;
        _lastCellEvent = 'Perekaman BTS nonaktif';
      }
    });

    if (value) {
      unawaited(_primeCellSurveyRecording());
    }
  }

  Future<void> _primeCellSurveyRecording() async {
    final cell = await _cellInfo.currentServingCell();
    if (!mounted || !_recordCellSurvey) return;

    if (cell == null) {
      _setStateAndRefreshMonitoring(() {
        _lastCellEvent = _streaming
            ? 'BTS aktif, menunggu data cell dari Android'
            : 'BTS aktif, menunggu GPS aktif';
      });
    } else {
      _updateCellStatus(cell);
      if (!mounted || !_recordCellSurvey) return;
      if (!_streaming) {
        _setStateAndRefreshMonitoring(
          () => _lastCellEvent = 'BTS siap, menunggu GPS aktif',
        );
      }
    }

    if (!_streaming) return;

    final currentPosition = await _gps.getCurrentPosition();
    if (!mounted || !_recordCellSurvey || currentPosition == null) return;

    if (currentPosition.accuracy > _maxAcceptedGpsAccuracyMeters) {
      _setStateAndRefreshMonitoring(() {
        _lastCellEvent =
            'BTS aktif, menunggu GPS akurat (${currentPosition.accuracy.toStringAsFixed(1)} m)';
      });
      return;
    }

    unawaited(_sendLocation(currentPosition, speedKmh: _speedKmh ?? 0));
  }

  void _addRoutePoint({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    double? headingDegrees,
    bool isSpeedAnomaly = false,
  }) {
    final next = _RoutePoint(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      recordedAt: DateTime.now(),
      headingDegrees: headingDegrees,
      isSpeedAnomaly: isSpeedAnomaly,
    );

    if (_routePoints.isNotEmpty) {
      final last = _routePoints.last;
      final distance = _haversineMeters(
        last.latitude,
        last.longitude,
        latitude,
        longitude,
      );
      if (distance < _minRouteDistanceMeters) {
        return;
      }
    }

    _routePoints.add(next);
    if (_routePoints.length > _maxRoutePoints) {
      _routePoints.removeRange(0, _routePoints.length - _maxRoutePoints);
    }
  }

  double? _headingFromPosition(Position pos, _RoutePoint? previous) {
    final compassHeading = _freshCompassHeading;
    final gpsHeading = _normalizeHeading(pos.heading);
    if (previous == null) return compassHeading ?? gpsHeading;

    final distance = _haversineMeters(
      previous.latitude,
      previous.longitude,
      pos.latitude,
      pos.longitude,
    );
    if (distance < _minRouteDistanceMeters) {
      return compassHeading ?? gpsHeading ?? previous.headingDegrees;
    }

    return _bearingDegrees(
      previous.latitude,
      previous.longitude,
      pos.latitude,
      pos.longitude,
    );
  }

  double? get _freshCompassHeading {
    final heading = _compassHeadingDegrees;
    final sampledAt = _lastCompassAt;
    if (heading == null || sampledAt == null) return null;
    if (DateTime.now().difference(sampledAt) > const Duration(seconds: 3)) {
      return null;
    }
    return heading;
  }

  double _smoothHeading(double? current, double next, double factor) {
    final normalized = _normalizeHeading(next) ?? 0;
    if (current == null) return normalized;

    final delta = ((normalized - current + 540) % 360) - 180;
    return (current + delta * factor + 360) % 360;
  }

  double? _normalizeHeading(double? degrees) {
    if (degrees == null || !degrees.isFinite || degrees < 0) return null;
    final normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _mapRotationForHeading(double? headingDegrees) {
    return _navigationMapRotation(headingDegrees);
  }

  double _bearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final fromLat = _toRadians(lat1);
    final toLat = _toRadians(lat2);
    final lonDelta = _toRadians(lon2 - lon1);
    final y = math.sin(lonDelta) * math.cos(toLat);
    final x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(lonDelta);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void _updateMapCamera({bool force = false}) {
    if (_routePoints.isEmpty) return;

    final latest = _routePoints.last;
    final target = latlong.LatLng(latest.latitude, latest.longitude);
    final isAuto = _followMode == _MapFollowMode.auto;
    final rotation = isAuto
        ? _mapRotationForHeading(_headingDegrees ?? latest.headingDegrees)
        : 0.0;
    final zoom = _currentMapZoom ?? 17.0;

    if (!isAuto && !force) return;

    _mapController.moveAndRotate(target, zoom, rotation);
  }

  double? get _currentMapZoom {
    try {
      return _mapController.camera.zoom;
    } catch (_) {
      return null;
    }
  }

  void _rotateMapToHeading() {
    if (_routePoints.isEmpty || _followMode != _MapFollowMode.auto) return;
    final latest = _routePoints.last;
    _mapController.rotate(
      _mapRotationForHeading(_headingDegrees ?? latest.headingDegrees),
    );
  }

  void _handleMapUserGesture() {
    if (!mounted) return;
    if (_followMode == _MapFollowMode.manual && _autoFollowReturnAt == null) {
      return;
    }

    _beginAutoFollowReturnCountdown();
    setState(() {
      _followMode = _MapFollowMode.manual;
      _mapControlsExpanded = false;
    });
  }

  void _zoomMapBy(double delta) {
    _handleMapUserGesture();

    latlong.LatLng? center;
    double? zoom;
    double? rotation;

    try {
      final camera = _mapController.camera;
      center = camera.center;
      zoom = camera.zoom;
      rotation = camera.rotation;
    } catch (_) {}

    if (center == null && _routePoints.isNotEmpty) {
      final latest = _routePoints.last;
      center = latlong.LatLng(latest.latitude, latest.longitude);
    }

    if (center == null) return;

    final nextZoom = ((zoom ?? 17.0) + delta).clamp(5.0, 19.0).toDouble();
    final latestHeading =
        _routePoints.isEmpty ? null : _routePoints.last.headingDegrees;
    final nextRotation = _followMode == _MapFollowMode.auto
        ? _mapRotationForHeading(_headingDegrees ?? latestHeading)
        : (rotation ?? 0.0);

    _mapController.moveAndRotate(center, nextZoom, nextRotation);
  }

  void _beginAutoFollowReturnCountdown() {
    _autoFollowReturnTimer?.cancel();
    _autoFollowCountdownTimer?.cancel();

    _autoFollowReturnAt = DateTime.now().add(_autoFollowReturnDelay);
    _autoFollowReturnSeconds = _autoFollowReturnDelay.inSeconds;

    _autoFollowCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncAutoFollowReturnCountdown(),
    );
    _autoFollowReturnTimer = Timer(
      _autoFollowReturnDelay,
      _returnToAutoFollowIfScheduled,
    );
  }

  void _syncAutoFollowReturnCountdown() {
    final returnAt = _autoFollowReturnAt;
    if (returnAt == null) {
      _autoFollowCountdownTimer?.cancel();
      _autoFollowCountdownTimer = null;
      return;
    }

    final remainingMs = returnAt.difference(DateTime.now()).inMilliseconds;
    final nextSeconds =
        (remainingMs / 1000).ceil().clamp(0, _autoFollowReturnDelay.inSeconds);
    if (_autoFollowReturnSeconds == nextSeconds || !mounted) return;

    setState(() => _autoFollowReturnSeconds = nextSeconds.toInt());
  }

  void _returnToAutoFollowIfScheduled() {
    if (!mounted || _autoFollowReturnAt == null) return;

    setState(() {
      _followMode = _MapFollowMode.auto;
      _mapControlsExpanded = false;
      _clearAutoFollowReturnCountdown();
    });
    _updateMapCamera(force: true);
  }

  void _clearAutoFollowReturnCountdown() {
    _autoFollowReturnTimer?.cancel();
    _autoFollowCountdownTimer?.cancel();
    _autoFollowReturnTimer = null;
    _autoFollowCountdownTimer = null;
    _autoFollowReturnAt = null;
    _autoFollowReturnSeconds = null;
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

  void _showOverspeedAlert(double speedKmh) {
    if (!mounted) return;

    final now = DateTime.now();
    final lastAlertAt = _lastOverspeedAlertAt;
    if (lastAlertAt != null &&
        now.difference(lastAlertAt) < const Duration(seconds: 12)) {
      return;
    }

    _lastOverspeedAlertAt = now;
    final speedText = speedKmh.toStringAsFixed(1);
    final limitText = _maxBillableSpeedKmh.toStringAsFixed(0);
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF991B1B),
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        content: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.speed_rounded,
                color: Color(0xFFB91C1C),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Batas kecepatan terlampaui',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$speedText km/h melewati batas $limitText km/h. Jalur ditandai merah.',
                    style: const TextStyle(
                      color: Color(0xFFFEE2E2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeviceDetails(
    Bike bike,
    ActiveBikeRental? rental,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceDetailsScreen(
          api: widget.api,
          bike: bike,
          rental: rental,
          displaySpeed: _speedKmh ?? rental?.currentSpeedKmh ?? 0,
          batteryPercent: _batteryPercent,
          networkType: _networkType,
          pointsSent: _routePoints.length,
          lastSentAt: _lastSentAt,
          locationMode: _locationMode,
          streaming: _streaming,
          now: _now,
          locationAccessGranted: _locationAccessGranted,
          locationAccessStatus: _locationAccessStatus,
          lastGpsReadAt: _lastGpsReadAt,
          accuracyMeters:
              _accuracyMeters ?? rental?.latestLocationPoint?.accuracyMeters,
          cellInfo: _currentCell,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bike = _bike;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
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
    final isRented = rental != null;

    if (!isRented) {
      return _buildIdleQrView(bike);
    } else {
      return _buildActiveRideView(bike, rental);
    }
  }

  Widget _buildIdleQrView(Bike bike) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: _buildTopOverlay(bike, isRented: false),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: QrRentalPanel(
                api: widget.api,
                hasAssignedBike: true,
                hasActiveRental: false,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: Color(0xFF10b981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('Sepeda Tersedia',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRideView(Bike bike, ActiveBikeRental rental) {
    return Stack(
      children: [
        Positioned.fill(
          child: _MiniRouteMap(
            height: MediaQuery.of(context).size.height,
            points: List.unmodifiable(_routePoints),
            latestAccuracyMeters:
                _accuracyMeters ?? rental.latestLocationPoint?.accuracyMeters,
            latestHeadingDegrees: _headingDegrees,
            mapType: _mapType,
            onMapTypeChanged: (value) => setState(() {
              _mapType = value;
              _mapControlsExpanded = false;
            }),
            followMode: _followMode,
            onFollowModeChanged: (value) {
              setState(() {
                _followMode = value;
                _mapControlsExpanded = false;
                _clearAutoFollowReturnCountdown();
              });
              _updateMapCamera(force: true);
            },
            controlsExpanded: _mapControlsExpanded,
            onControlsToggle: () => setState(
              () => _mapControlsExpanded = !_mapControlsExpanded,
            ),
            onUserGesture: _handleMapUserGesture,
            onZoomIn: () => _zoomMapBy(1),
            onZoomOut: () => _zoomMapBy(-1),
            autoReturnSeconds: _autoFollowReturnSeconds,
            mapController: _mapController,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: _buildTopOverlay(bike, isRented: true),
        ),
        // Banner besar dihilangkan sesuai saran lead agar tidak menutupi speedometer

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
          top: MediaQuery.of(context).padding.top + 90,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Kiri: Angka Kecepatan
                      Text(
                        (_speedKmh ?? rental.currentSpeedKmh ?? 0.0)
                            .toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -2.0,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Kanan: Detail & Label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isGpsWarmupActive
                                    ? Icons.sync_rounded
                                    : Icons.speed_rounded,
                                color: _isGpsWarmupActive
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF38BDF8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isGpsWarmupActive ? 'MENGUNCI' : 'KECEPATAN',
                                style: TextStyle(
                                  color: _isGpsWarmupActive
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gps_fixed,
                                  size: 12, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                _accuracyMeters == null
                                    ? 'GPS -'
                                    : 'Akurasi ${_accuracyMeters!.toStringAsFixed(0)}m',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'km/h',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE2E8F0),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_locationAccessGranted && _routePoints.length < 2)
          Positioned(
            top: MediaQuery.of(context).padding.top + 198,
            left: 24,
            right: 24,
            child: _MapHintChip(
              message: _routePoints.isEmpty
                  ? 'Menunggu GPS valid'
                  : 'Jalur muncul setelah sepeda bergerak',
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          right: 16,
          bottom: _mapControlsExpanded ? 305 : 216,
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
              onPressed: () {
                setState(() {
                  _followMode = _MapFollowMode.auto;
                  _mapControlsExpanded = false;
                  _clearAutoFollowReturnCountdown();
                });

                if (_routePoints.isNotEmpty) {
                  _updateMapCamera(force: true);
                } else if (rental.latestLocationPoint?.latitude != null) {
                  _mapController.moveAndRotate(
                    latlong.LatLng(
                      rental.latestLocationPoint!.latitude!,
                      rental.latestLocationPoint!.longitude!,
                    ),
                    17,
                    0,
                  );
                }
              },
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
              ],
            ),

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
                icon: const Icon(Icons.logout_rounded),
                color: const Color(0xFFEF4444),
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
    return ValueListenableBuilder<int>(
      valueListenable: _monitoringPanelRevision,
      builder: (context, _, __) {
        final currentBike = _bike ?? bike;
        final currentRental = _summary?.rental ?? rental;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: EdgeInsets.zero,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Awal (Content Lowered)
                Container(
                  padding: const EdgeInsets.only(
                      top: 35, bottom: 15, left: 16, right: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 24),
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Monitoring & Kontrol Unit',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22, // Dikecilkan (dari 26 ke 22)
                          color: Color(0xFF0F172A),
                          letterSpacing: -1.0,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: _isRefreshing
                              ? null
                              : () async {
                                  _setStateAndRefreshMonitoring(
                                      () => _isRefreshing = true);
                                  _refreshController.repeat(); // Mulai berputar

                                  try {
                                    // Memanggil ulang data dari server
                                    await Future.wait([
                                      _loadBike(),
                                      _loadRentalSummary(),
                                      _loadBattery(),
                                      Future.delayed(const Duration(
                                          milliseconds:
                                              800)), // Minimal durasi putaran
                                    ]);
                                  } finally {
                                    if (mounted) {
                                      _refreshController
                                          .stop(); // Berhenti berputar
                                      _refreshController.reset();
                                      _setStateAndRefreshMonitoring(
                                          () => _isRefreshing = false);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Data berhasil diperbarui dari server'),
                                            duration: Duration(seconds: 1),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          icon: RotationTransition(
                            turns: _refreshController,
                            child: const Icon(Icons.refresh_rounded, size: 32),
                          ),
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Status Koneksi & GPS',
                            'Pantau real-time koneksi perangkat dengan server'),
                        _Panel(
                          child: _StatusBanner(
                            streaming: _streaming,
                            mode: _locationMode,
                            sending: _sending,
                            serverMessage: _lastServerMsg,
                            lastGpsReadAt: _lastGpsReadAt,
                            lastSentAt: _lastSentAt,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CellSurveyRecordingControl(
                          enabled: _recordCellSurvey,
                          onChanged: _setCellSurveyRecording,
                        ),
                        const SizedBox(height: 24),
                        _sectionHeader('Informasi Sepeda & Perangkat',
                            'Identitas unit, status daya baterai, dan stabilitas transmisi data'),
                        _Panel(
                          child: _DeviceSummary(
                            bike: currentBike,
                            batteryPercent: _batteryPercent,
                            networkType: _networkType,
                            recordCellSurvey: _recordCellSurvey,
                            cellInfo: _currentCell,
                            cellEvent: _lastCellEvent,
                            pointsSent: _routePoints.length,
                            locationMode: _locationMode,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openDeviceDetails(currentBike, currentRental);
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Buka detail perangkat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionHeader('Ringkasan Perjalanan',
                            'Statistik kecepatan, jarak, dan estimasi biaya sewa'),
                        _Panel(
                          backgroundColor:
                              const Color(0xFF10B981), // Bright Emerald Green
                          child: _CompactStatsRow(
                            speedKmh: _smoothedSpeedKmh,
                            distanceKm:
                                currentRental?.totalDistanceKilometers ?? 0,
                            totalCost: currentRental?.totalCost ?? 0,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _sectionHeader('Status Kesiapan Perangkat',
                            'Informasi dan ringkasan diagnostik sensor serta izin akses perangkat secara real-time'),
                        _FieldTestChecklist(
                          locationAccess: _locationAccessGranted,
                          gpsEnabled: _locationAccessStatus !=
                              LocationAccessStatus.serviceDisabled,
                          autoStart: _streaming,
                          networkType: _networkType,
                          lastGpsAt: _lastGpsReadAt,
                          lastServerAt: _lastSentAt,
                          accuracyMeters: _accuracyMeters ??
                              currentRental
                                  ?.latestLocationPoint?.accuracyMeters,
                          rentalActive: currentRental != null,
                          recordCellSurvey: _recordCellSurvey,
                        ),
                        const SizedBox(
                            height:
                                40), // Ruang ekstra di bawah agar kartu terakhir terlihat penuh
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A), // Deep Black
              fontWeight: FontWeight.w900,
              fontSize: 20, // Diperbesar agar efek bold lebih terasa
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold, // Diubah jadi bold (w700)
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellSurveyRecordingControl extends StatelessWidget {
  const _CellSurveyRecordingControl({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: enabled ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
      backgroundColor:
          enabled ? const Color(0xFFFFF7ED) : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFF97316),
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          Icons.cell_tower_rounded,
          color: enabled ? const Color(0xFFF97316) : const Color(0xFF64748B),
        ),
        title: const Text(
          'Rekam BTS/Cell',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          enabled
              ? 'Aktif. Data cell akan dikirim bersama GPS.'
              : 'Nonaktif. GPS tetap dikirim tanpa data BTS.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
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
    required this.recordCellSurvey,
  });

  final bool locationAccess;
  final bool gpsEnabled;
  final bool autoStart;
  final String networkType;
  final DateTime? lastGpsAt;
  final DateTime? lastServerAt;
  final double? accuracyMeters;
  final bool rentalActive;
  final bool recordCellSurvey;

  @override
  Widget build(BuildContext context) {
    final accuracyOk = accuracyMeters != null && accuracyMeters! <= 50;
    final gpsFresh = _isFresh(lastGpsAt, const Duration(seconds: 15));
    final serverFresh = _isFresh(lastServerAt, const Duration(seconds: 15));

    return _Panel(
      borderColor: const Color(0xFFE2E8F0),
      backgroundColor: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
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
            isWarning: !rentalActive,
          ),
          _CheckRow(
            ok: recordCellSurvey,
            label: 'Rekam BTS',
            detail: recordCellSurvey ? 'Aktif' : 'Nonaktif',
            isWarning: !recordCellSurvey,
          ),
        ],
      ),
    );
  }

  bool _isFresh(DateTime? dt, Duration maxAge) {
    if (dt == null) return false;
    final age = DateTime.now().difference(dt);
    return !age.isNegative && age <= maxAge;
  }

  String _relativeTimeLabel(DateTime? dt) {
    if (dt == null) return 'Belum ada';
    final rawDiff = DateTime.now().difference(dt);
    final diff = rawDiff.isNegative ? Duration.zero : rawDiff;
    if (diff.inSeconds < 60) return '${diff.inSeconds}s lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    return '${diff.inHours}j lalu';
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.ok,
    required this.label,
    required this.detail,
    this.isWarning = false,
  });

  final bool ok;
  final String label;
  final String detail;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final statusColor = isWarning
        ? const Color(0xFFB54708)
        : (ok ? const Color(0xFF027A48) : const Color(0xFFB42318));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.error_outline_rounded
                : (ok ? Icons.check_circle_rounded : Icons.cancel_rounded),
            size: 20,
            color: ok
                ? const Color(0xFF12B76A)
                : (isWarning
                    ? const Color(0xFFF79009)
                    : const Color(0xFFF04438)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              color: statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
    final statusColor =
        streaming ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  streaming ? 'SISTEM ONLINE' : 'SISTEM SIAGA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  mode.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _StatusRow(
            label: 'Penerimaan GPS',
            value:
                lastGpsReadAt != null ? _timeDiff(lastGpsReadAt!) : 'Belum ada',
            icon: Icons.location_on_rounded,
            isActive: lastGpsReadAt != null,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Sinkronisasi Server',
            value: lastSentAt != null
                ? _timeDiff(lastSentAt!)
                : 'Menghubungkan...',
            icon: Icons.cloud_upload_rounded,
            isActive: sending,
          ),
          if (serverMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverMessage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
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
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isActive,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color:
                isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutePoint {
  const _RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    this.headingDegrees,
    this.isSpeedAnomaly = false,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime recordedAt;
  final double? headingDegrees;
  final bool isSpeedAnomaly;
}

class _PendingLocationUpdate {
  const _PendingLocationUpdate({
    required this.position,
    required this.recordedAt,
    this.speedKmh,
  });

  final Position position;
  final double? speedKmh;
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

enum _BikeMapType {
  standard('Standar', Icons.map_outlined),
  satellite('Satelit', Icons.satellite_alt_outlined);

  const _BikeMapType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _MapFollowMode {
  auto('Auto', Icons.explore_outlined),
  manual('Manual', Icons.pan_tool_alt_outlined);

  const _MapFollowMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

double _navigationMapRotation(double? headingDegrees) {
  if (headingDegrees == null || !headingDegrees.isFinite) return 0;
  final heading = headingDegrees % 360;
  final normalizedHeading = heading < 0 ? heading + 360 : heading;
  return (360 - normalizedHeading) % 360;
}

bool _isUserMapGesture(MapEventSource source) {
  return switch (source) {
    MapEventSource.dragStart ||
    MapEventSource.dragEnd ||
    MapEventSource.multiFingerGestureStart ||
    MapEventSource.multiFingerEnd ||
    MapEventSource.doubleTap ||
    MapEventSource.doubleTapHold ||
    MapEventSource.scrollWheel =>
      true,
    _ => false,
  };
}

class _MiniRouteMap extends StatelessWidget {
  const _MiniRouteMap({
    this.height = 170,
    required this.points,
    required this.latestAccuracyMeters,
    required this.latestHeadingDegrees,
    required this.mapType,
    required this.onMapTypeChanged,
    required this.followMode,
    required this.onFollowModeChanged,
    required this.controlsExpanded,
    required this.onControlsToggle,
    required this.onUserGesture,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.autoReturnSeconds,
    this.mapController,
  });

  final double height;
  final List<_RoutePoint> points;
  final double? latestAccuracyMeters;
  final double? latestHeadingDegrees;
  final _BikeMapType mapType;
  final ValueChanged<_BikeMapType> onMapTypeChanged;
  final _MapFollowMode followMode;
  final ValueChanged<_MapFollowMode> onFollowModeChanged;
  final bool controlsExpanded;
  final VoidCallback onControlsToggle;
  final VoidCallback onUserGesture;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final int? autoReturnSeconds;
  final MapController? mapController;

  static const _fallbackCenter = latlong.LatLng(-8.583235, 116.116768);

  @override
  Widget build(BuildContext context) {
    final mapPoints = points
        .map((point) => latlong.LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final latestPoint = mapPoints.isEmpty ? _fallbackCenter : mapPoints.last;
    final pointCount = points.length;
    final latestHeading = latestHeadingDegrees ??
        (points.isEmpty ? null : points.last.headingDegrees);
    final markerRotation =
        followMode == _MapFollowMode.auto ? 0.0 : (latestHeading ?? 0);
    final initialRotation = followMode == _MapFollowMode.auto
        ? _navigationMapRotation(latestHeading)
        : 0.0;
    final isSatellite = mapType == _BikeMapType.satellite;
    final routeColor =
        isSatellite ? const Color(0xFF22D3EE) : const Color(0xFF0EA5E9);
    final latestAccuracy = latestAccuracyMeters;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: latestPoint,
                initialZoom: pointCount == 0 ? 15 : 17,
                initialRotation: initialRotation,
                minZoom: 5,
                maxZoom: 19,
                onMapEvent: (event) {
                  if (_isUserMapGesture(event.source)) onUserGesture();
                },
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
                    polylines: _buildRoutePolylines(mapPoints, routeColor),
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
                    rotate: true,
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
                        rotationDegrees: markerRotation,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            bottom: 150,
            child: _MapZoomDock(
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
            ),
          ),
          if (autoReturnSeconds != null &&
              autoReturnSeconds! > 0 &&
              followMode == _MapFollowMode.manual)
            Positioned(
              left: 12,
              bottom: 246,
              child: _AutoFollowReturnChip(seconds: autoReturnSeconds!),
            ),
          Positioned(
            right: 12,
            bottom: 150,
            child: _MapControlsDock(
              expanded: controlsExpanded,
              onToggle: onControlsToggle,
              followMode: followMode,
              onFollowModeChanged: onFollowModeChanged,
              mapType: mapType,
              onMapTypeChanged: onMapTypeChanged,
            ),
          ),
        ],
      ),
    );
  }

  TileLayer _buildTileLayer() {
    if (mapType == _BikeMapType.satellite) {
      return TileLayer(
        key: const ValueKey('satellite-base-tiles'),
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.smartbike.mobile_bike',
        maxNativeZoom: 19,
      );
    }

    return TileLayer(
      key: const ValueKey('standard-base-tiles'),
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.smartbike.mobile_bike',
      maxNativeZoom: 19,
    );
  }

  TileLayer _buildLabelLayer() {
    return TileLayer(
      key: const ValueKey('satellite-label-tiles'),
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.smartbike.mobile_bike',
      maxNativeZoom: 19,
    );
  }

  List<Polyline> _buildRoutePolylines(
    List<latlong.LatLng> mapPoints,
    Color routeColor,
  ) {
    const anomalyColor = Color(0xFFEF4444);
    final shadows = <Polyline>[];
    final lines = <Polyline>[];

    for (var i = 1; i < mapPoints.length; i++) {
      final isAnomalySegment = points[i].isSpeedAnomaly;
      final color = isAnomalySegment ? anomalyColor : routeColor;
      final segment = [mapPoints[i - 1], mapPoints[i]];

      shadows.add(
        Polyline(
          points: segment,
          strokeWidth: 7,
          color: color.withValues(alpha: .26),
        ),
      );
      lines.add(
        Polyline(
          points: segment,
          strokeWidth: 4,
          color: color,
        ),
      );
    }

    return [...shadows, ...lines];
  }

  Marker _buildMarker({
    required latlong.LatLng point,
    required IconData icon,
    required Color color,
    required double size,
    double rotationDegrees = 0,
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
        child: Transform.rotate(
          angle: rotationDegrees * math.pi / 180,
          child: Icon(icon, color: color, size: size * .58),
        ),
      ),
    );
  }
}

class _MapZoomDock extends StatelessWidget {
  const _MapZoomDock({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapZoomButton(
            icon: Icons.add_rounded,
            tooltip: 'Perbesar peta',
            onPressed: onZoomIn,
          ),
          const SizedBox(
            width: 34,
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _MapZoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'Perkecil peta',
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 42,
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoFollowReturnChip extends StatelessWidget {
  const _AutoFollowReturnChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: .18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.navigation_rounded,
              size: 15,
              color: Color(0xFF5EEAD4),
            ),
            const SizedBox(width: 7),
            Text(
              'Ikuti lagi ${seconds}dtk',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHintChip extends StatelessWidget {
  const _MapHintChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: .84),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: .16),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 15,
                  color: Color(0xFF93C5FD),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 2,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlsDock extends StatelessWidget {
  const _MapControlsDock({
    required this.expanded,
    required this.onToggle,
    required this.followMode,
    required this.onFollowModeChanged,
    required this.mapType,
    required this.onMapTypeChanged,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final _MapFollowMode followMode;
  final ValueChanged<_MapFollowMode> onFollowModeChanged;
  final _BikeMapType mapType;
  final ValueChanged<_BikeMapType> onMapTypeChanged;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onToggle,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
                Positioned(
                  right: 9,
                  bottom: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, right: 8),
                child: Text(
                  'Mode peta',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onToggle,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _MapFollowToggle(
            value: followMode,
            onChanged: onFollowModeChanged,
          ),
          const SizedBox(height: 6),
          _MapTypeToggle(
            value: mapType,
            onChanged: onMapTypeChanged,
          ),
        ],
      ),
    );
  }
}

class _MapFollowToggle extends StatelessWidget {
  const _MapFollowToggle({
    required this.value,
    required this.onChanged,
  });

  final _MapFollowMode value;
  final ValueChanged<_MapFollowMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return _MapSegmentedControl<_MapFollowMode>(
      options: _MapFollowMode.values,
      value: value,
      labelFor: (mode) => mode.label,
      iconFor: (mode) => mode.icon,
      onChanged: onChanged,
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
    return _MapSegmentedControl<_BikeMapType>(
      options: _BikeMapType.values,
      value: value,
      labelFor: (type) => type.label,
      iconFor: (type) => type.icon,
      onChanged: onChanged,
    );
  }
}

class _MapSegmentedControl<T> extends StatelessWidget {
  const _MapSegmentedControl({
    required this.options,
    required this.value,
    required this.labelFor,
    required this.iconFor,
    required this.onChanged,
  });

  final List<T> options;
  final T value;
  final String Function(T value) labelFor;
  final IconData Function(T value) iconFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => _MapSegmentButton<T>(
                value: option,
                selected: option == value,
                label: labelFor(option),
                icon: iconFor(option),
                onSelected: onChanged,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MapSegmentButton<T> extends StatelessWidget {
  const _MapSegmentButton({
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final T value;
  final bool selected;
  final String label;
  final IconData icon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF475569);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 38,
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: .28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
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

class _CompactStatsRow extends StatelessWidget {
  const _CompactStatsRow({
    required this.speedKmh,
    required this.distanceKm,
    required this.totalCost,
  });

  final double speedKmh;
  final double distanceKm;
  final int totalCost;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sisi Kiri: Speed (Besar)
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Speed',
                  style: TextStyle(
                    fontSize: 13, // Diperbesar (dari 10 ke 13)
                    fontWeight: FontWeight.w900,
                    color: Colors.white, // Lebih cerah (dari white70 ke white)
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        speedKmh.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 54, // Diperbesar (dari 42 ke 54)
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          fontSize: 16, // Diperbesar (dari 14 ke 16)
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pemisah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 1,
              color: Colors.white24,
            ),
          ),

          // Sisi Kanan: Jarak dan Biaya (Ditumpuk)
          Expanded(
            flex: 15,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CompactInfoRow(
                  label: 'Distance',
                  value: '${distanceKm.toStringAsFixed(2)} km',
                  icon: Icons.straighten_rounded,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                _CompactInfoRow(
                  label: 'Total Cost',
                  value: _formatRupiah(totalCost),
                  icon: Icons.account_balance_wallet_rounded,
                  emphasized: true,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ??
        (emphasized ? const Color(0xFF12B76A) : const Color(0xFF64748B));
    final labelColor = color?.withValues(alpha: 0.7) ?? const Color(0xFF64748B);

    return Row(
      children: [
        Icon(icon, size: 14, color: baseColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13, // Diperbesar (dari 10 ke 13)
              fontWeight: FontWeight.w900,
              color: color != null
                  ? Colors.white.withValues(alpha: 0.9)
                  : labelColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 18 : 16, // Diperbesar (dari 12/14 ke 16/18)
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
            color: color ??
                (emphasized
                    ? const Color(0xFF064E3B)
                    : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

class _DeviceSummary extends StatelessWidget {
  const _DeviceSummary({
    required this.bike,
    required this.batteryPercent,
    required this.networkType,
    required this.recordCellSurvey,
    required this.cellInfo,
    required this.cellEvent,
    required this.pointsSent,
    required this.locationMode,
  });

  final Bike bike;
  final int batteryPercent;
  final String networkType;
  final bool recordCellSurvey;
  final CellInfoSnapshot? cellInfo;
  final String cellEvent;
  final int pointsSent;
  final String locationMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pedal_bike_rounded,
                  size: 24, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bike.code} - ${bike.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricItemSmall(
                    label: 'BATERAI',
                    value: '$batteryPercent%',
                    icon: Icons.battery_charging_full_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricItemSmall(
                    label: 'SINYAL',
                    value: networkType.toUpperCase(),
                    icon: Icons.wifi_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricItemSmall(
                    label: 'DATA',
                    value: '$pointsSent Pts',
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricItemSmall(
                    label: 'MODE GPS',
                    value: locationMode.toUpperCase(),
                    icon: Icons.explore_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricItemSmall(
              label: 'BTS/CELL',
              value:
                  recordCellSurvey ? cellInfo?.shortLabel ?? cellEvent : 'NONAKTIF',
              icon: Icons.cell_tower_rounded,
              color: recordCellSurvey
                  ? const Color(0xFFF97316)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricItemSmall extends StatelessWidget {
  const _MetricItemSmall({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
