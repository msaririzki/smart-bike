import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/rental.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import 'active_rental_detail.dart';
import 'idle_warning_dialog.dart';
import 'map_widget.dart';

class ActiveRentalScreen extends StatefulWidget {
  const ActiveRentalScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<ActiveRentalScreen> createState() => _ActiveRentalScreenState();
}

class _ActiveRentalScreenState extends State<ActiveRentalScreen> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final List<LatLng> _routePoints = [];
  Timer? _refreshTimer;
  Timer? _durationTimer;
  Rental? _rental;
  int? _routeRentalId;
  int? _shownIdleWarningRentalId;
  int? _shownIdleBillingRentalId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isFinishing = false;
  bool _idleDialogOpen = false;
  bool _queuedVisibleRefresh = false;
  String? _error;
  DateTime _now = DateTime.now();

  // Idle settings dari backend.
  int? _idleWarningSeconds;
  int? _idleBillingAmount;
  int? _idleBillingIntervalSeconds;

  @override
  void initState() {
    super.initState();
    _loadRental();
    _loadIdleSettings();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadRental(silent: true);
      }
    });
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  /// Fetch idle settings dari backend (fire-and-forget, tidak blocking)
  Future<void> _loadIdleSettings() async {
    try {
      final settings = await widget.api.idleSettings();
      if (mounted) {
        setState(() {
          _idleWarningSeconds = settings['idle_warning_after_seconds'] as int?;
          _idleBillingAmount = settings['idle_billing_amount'] as int?;
          _idleBillingIntervalSeconds =
              settings['idle_billing_interval_seconds'] as int?;
        });
      }
    } catch (_) {
      // Fallback: gunakan default, teks dialog tetap generic
    }
  }

  Future<void> _loadRental({bool silent = false}) async {
    if (!mounted) {
      return;
    }

    if (_isRefreshing) {
      if (!silent) {
        _queuedVisibleRefresh = true;
      }
      return;
    }

    setState(() {
      _isRefreshing = true;
      if (!silent) {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final detail = await widget.api.activeRentalDetail();
      if (!mounted) {
        return;
      }

      final rental = detail == null ? null : Rental.fromJson(detail);
      final routeHistory = rental == null
          ? null
          : await _loadRouteHistory(rental);
      if (!mounted) {
        return;
      }

      setState(() {
        _rental = rental;
        _syncRoutePoints(rental, routeHistory: routeHistory);
        _error = null;
      });
      _handleIdleStatus(rental);
    } on ApiException catch (error) {
      if (mounted && !silent) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _error = 'Gagal memuat rental aktif.');
      }
    } finally {
      if (mounted) {
        final shouldRunQueuedRefresh = _queuedVisibleRefresh;
        _queuedVisibleRefresh = false;
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        if (shouldRunQueuedRefresh) {
          unawaited(_loadRental());
        }
      }
    }
  }

  Future<bool> _finishRental({bool closeScreen = true}) async {
    if (_isFinishing) {
      return false;
    }

    final rental = _rental;
    if (rental == null) {
      return false;
    }

    setState(() => _isFinishing = true);
    try {
      final finished = await widget.api.finishRental(rental.id);
      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sewa selesai. Total ${_currency.format(finished.totalCost)}.',
          ),
        ),
      );
      if (closeScreen) {
        Navigator.of(context).pop(true);
      }
      return true;
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Gagal menyelesaikan sewa.');
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }

    return false;
  }

  Future<List<LatLng>?> _loadRouteHistory(Rental rental) async {
    try {
      final points = await widget.api.rentalLocationPoints(rental.id);
      return points.map((point) => point.latLng).toList();
    } catch (_) {
      return null;
    }
  }

  void _syncRoutePoints(Rental? rental, {List<LatLng>? routeHistory}) {
    if (rental == null) {
      _routeRentalId = null;
      _routePoints.clear();
      return;
    }

    if (_routeRentalId != rental.id) {
      _routeRentalId = rental.id;
      _routePoints.clear();
    }

    if (routeHistory != null) {
      _routePoints
        ..clear()
        ..addAll(_cleanRouteHistory(routeHistory));
    }
  }

  List<LatLng> _cleanRouteHistory(List<LatLng> points) {
    if (points.length < 2) {
      return points;
    }

    final cleaned = <LatLng>[points.first];
    for (final point in points.skip(1)) {
      final distance = calculateDistance(cleaned.last, point);
      if (distance <= 250) {
        cleaned.add(point);
      }
    }

    return cleaned;
  }

  void _handleIdleStatus(Rental? rental) {
    if (!mounted) {
      return;
    }

    if (rental?.status == 'idle_warning') {
      final rentalId = rental!.id;
      _shownIdleBillingRentalId = null;
      if (!_idleDialogOpen &&
          !_isFinishing &&
          _shownIdleWarningRentalId != rentalId) {
        _shownIdleWarningRentalId = rentalId;
        _showIdleDialog(rentalId);
      }
      return;
    }

    if (rental?.status == 'idle_billing') {
      final rentalId = rental!.id;
      _shownIdleWarningRentalId = null;
      if (!_idleDialogOpen &&
          !_isFinishing &&
          _shownIdleBillingRentalId != rentalId) {
        _shownIdleBillingRentalId = rentalId;
        _showIdleBillingDialog(rental);
      }
      return;
    }

    _shownIdleWarningRentalId = null;
    _shownIdleBillingRentalId = null;

    if (_idleDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _idleDialogOpen = false;
    }
  }

  void _closeIdleDialog() {
    if (!_idleDialogOpen || !mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    _idleDialogOpen = false;
  }

  void _showIdleDialog(int rentalId) {
    _idleDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isLoading = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return IdleWarningDialog(
              isLoading: isLoading,
              idleWarningSeconds: _idleWarningSeconds,
              idleBillingAmount: _idleBillingAmount,
              idleBillingIntervalSeconds: _idleBillingIntervalSeconds,
              errorMessage: dialogError,
              onContinue: () async {
                setDialogState(() {
                  isLoading = true;
                  dialogError = null;
                });

                try {
                  await widget.api.continueIdle(rentalId);
                  if (!mounted) {
                    return;
                  }

                  _closeIdleDialog();
                  _showMessage(
                    'Peringatan dikonfirmasi. Lanjut bergerak agar biaya idle tidak berjalan.',
                  );
                  await _loadRental(silent: true);
                } on ApiException catch (error) {
                  if (mounted) {
                    setDialogState(() {
                      isLoading = false;
                      dialogError = error.message;
                    });
                  }
                } catch (_) {
                  if (mounted) {
                    setDialogState(() {
                      isLoading = false;
                      dialogError = 'Gagal melanjutkan sewa. Coba lagi.';
                    });
                  }
                }
              },
              onFinish: () async {
                setDialogState(() {
                  isLoading = true;
                  dialogError = null;
                });

                final screenNavigator = Navigator.of(this.context);
                final success = await _finishRental(closeScreen: false);
                if (!mounted) {
                  return;
                }

                if (success) {
                  _closeIdleDialog();
                  screenNavigator.pop(true);
                  return;
                }

                if (dialogContext.mounted) {
                  setDialogState(() {
                    isLoading = false;
                    dialogError = 'Gagal menyelesaikan sewa. Coba lagi.';
                  });
                }
              },
            );
          },
        );
      },
    ).whenComplete(() => _idleDialogOpen = false);
  }

  void _showIdleBillingDialog(Rental rental) {
    _idleDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xffdc2626),
            size: 42,
          ),
          title: const Text('Biaya Diam Berjalan'),
          content: Text(
            'Sepeda masih tidak bergerak. Biaya idle sekarang berjalan dan total biaya idle saat ini ${_currency.format(rental.idleCost)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
            FilledButton(
              onPressed: _isFinishing
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      await _finishRental();
                    },
              child: const Text('Selesaikan Sewa'),
            ),
          ],
        );
      },
    ).whenComplete(() => _idleDialogOpen = false);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final rental = _rental;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 255, 254),
      appBar: AppBar(
        title: const Text(
          'Rental Aktif',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color.fromARGB(255, 253, 255, 254),
        foregroundColor: const Color(0xff073f3a),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isRefreshing ? null : () => _loadRental(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRental,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (rental == null)
                    const _NoActiveRental()
                  else
                    Column(
                      children: [
                        if (_isIdleAlertStatus(rental.status))
                          _IdleAlertBanner(
                            rental: rental,
                            currency: _currency,
                            idleBillingAmount: _idleBillingAmount,
                            idleBillingIntervalSeconds:
                                _idleBillingIntervalSeconds,
                          ),
                        ActiveRentalDetail(
                          rental: rental,
                          currency: _currency,
                          duration: _durationFor(rental),
                          routePoints: List.unmodifiable(_routePoints),
                          idleBillingAmount: _idleBillingAmount,
                          idleBillingIntervalSeconds:
                              _idleBillingIntervalSeconds,
                        ),
                      ],
                    ),
                ],
              ),
            ),
      bottomNavigationBar: rental == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FilledButton.icon(
                onPressed: _isFinishing ? null : () => _finishRental(),
                icon: _isFinishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(
                  _isFinishing ? 'Menyelesaikan...' : 'Selesaikan Sewa',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
    );
  }

  Duration _durationFor(Rental rental) {
    final startedAt = rental.startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }

    final duration = _now.difference(startedAt);
    return duration.isNegative ? Duration.zero : duration;
  }
}

class _IdleAlertBanner extends StatelessWidget {
  const _IdleAlertBanner({
    required this.rental,
    required this.currency,
    this.idleBillingAmount,
    this.idleBillingIntervalSeconds,
  });

  final Rental rental;
  final NumberFormat currency;
  final int? idleBillingAmount;
  final int? idleBillingIntervalSeconds;

  @override
  Widget build(BuildContext context) {
    final isBilling = rental.status == 'idle_billing';
    final background = isBilling
        ? const Color(0xfffff1f3)
        : const Color(0xfffffaeb);
    final border = isBilling
        ? const Color(0xfffda29b)
        : const Color(0xfffedf89);
    final color = isBilling ? const Color(0xffb42318) : const Color(0xffb54708);
    final title = isBilling
        ? 'Biaya diam sedang berjalan'
        : 'Sepeda diam terlalu lama';
    final rate = _idleRateText();
    final message = isBilling
        ? 'Segera lanjutkan perjalanan atau selesaikan sewa. Biaya idle saat ini ${currency.format(rental.idleCost)}.'
        : 'Pilih lanjutkan di dialog atau selesaikan sewa agar denda diam tidak berjalan.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isBilling
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(message),
                if (rate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    rate,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _idleRateText() {
    final amount = idleBillingAmount;
    if (amount == null || amount <= 0) return null;

    final formatted = currency.format(amount);
    final interval = idleBillingIntervalSeconds;
    if (interval == null || interval <= 0) {
      return 'Tarif idle: $formatted per interval.';
    }

    final intervalText = interval >= 60
        ? '${interval ~/ 60} menit'
        : '$interval detik';
    return 'Tarif idle: $formatted per $intervalText.';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f3),
        border: Border.all(color: const Color(0xfffda29b)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _NoActiveRental extends StatelessWidget {
  const _NoActiveRental();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffd0d5dd)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, size: 40),
          SizedBox(height: 12),
          Text('Belum ada rental aktif.'),
        ],
      ),
    );
  }
}

bool _isIdleAlertStatus(String status) {
  return status == 'idle_warning' || status == 'idle_billing';
}
