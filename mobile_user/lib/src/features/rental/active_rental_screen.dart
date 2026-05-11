import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/rental.dart';
import '../../services/api_client.dart';
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
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isFinishing = false;
  bool _idleDialogOpen = false;
  bool _queuedVisibleRefresh = false;
  String? _error;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRental();
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
      setState(() {
        _rental = rental;
        _syncRoutePoints(rental);
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

  void _syncRoutePoints(Rental? rental) {
    if (rental == null) {
      _routeRentalId = null;
      _routePoints.clear();
      return;
    }

    if (_routeRentalId != rental.id) {
      _routeRentalId = rental.id;
      _routePoints.clear();
    }

    final latitude = rental.latitude;
    final longitude = rental.longitude;
    if (latitude == null || longitude == null) {
      return;
    }

    final nextPoint = LatLng(latitude, longitude);
    if (_routePoints.isEmpty ||
        calculateDistance(_routePoints.last, nextPoint) >= 1) {
      _routePoints.add(nextPoint);
    }
  }

  void _handleIdleStatus(Rental? rental) {
    if (!mounted) {
      return;
    }

    if (rental?.status == 'idle_warning') {
      final rentalId = rental!.id;
      if (!_idleDialogOpen &&
          !_isFinishing &&
          _shownIdleWarningRentalId != rentalId) {
        _shownIdleWarningRentalId = rentalId;
        _showIdleDialog(rentalId);
      }
      return;
    }

    _shownIdleWarningRentalId = null;

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

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return IdleWarningDialog(
              isLoading: isLoading,
              onContinue: () async {
                setDialogState(() => isLoading = true);

                try {
                  await widget.api.continueIdle(rentalId);
                  if (!mounted) {
                    return;
                  }

                  _closeIdleDialog();
                  _showMessage('Sewa dilanjutkan. Biaya idle mulai berjalan.');
                  await _loadRental(silent: true);
                } on ApiException catch (error) {
                  if (mounted) {
                    setDialogState(() => isLoading = false);
                    _showMessage(error.message);
                  }
                } catch (_) {
                  if (mounted) {
                    setDialogState(() => isLoading = false);
                    _showMessage('Gagal melanjutkan sewa.');
                  }
                }
              },
              onFinish: () async {
                setDialogState(() => isLoading = true);

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
                  setDialogState(() => isLoading = false);
                }
              },
            );
          },
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
      appBar: AppBar(
        title: const Text('Rental Aktif'),
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
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (rental == null)
                    const _NoActiveRental()
                  else
                    ActiveRentalDetail(
                      rental: rental,
                      currency: _currency,
                      duration: _durationFor(rental),
                      routePoints: List.unmodifiable(_routePoints),
                      isFinishing: _isFinishing,
                      onFinish: () => _finishRental(),
                    ),
                ],
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
