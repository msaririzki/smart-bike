import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
}

class LocationAccessResult {
  const LocationAccessResult(this.status);

  final LocationAccessStatus status;

  bool get granted => status == LocationAccessStatus.granted;
}

class GpsService {
  /// Pastikan GPS aktif dan izin lokasi foreground sudah diberikan.
  Future<LocationAccessResult> ensureLocationAccess({
    bool requestIfDenied = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAccessResult(LocationAccessStatus.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult(LocationAccessStatus.deniedForever);
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult(LocationAccessStatus.denied);
    }

    await Permission.notification.request();

    return const LocationAccessResult(LocationAccessStatus.granted);
  }

  /// Ambil posisi sekali.
  Future<Position?> getCurrentPosition() async {
    try {
      final access = await ensureLocationAccess(requestIfDenied: false);
      if (!access.granted) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream posisi real-time saat perangkat bergerak minimal 1 meter.
  Stream<Position> positionStream() {
    final locationSettings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Smart Bike sedang mengirim lokasi',
              notificationText:
                  'GPS sepeda aktif agar admin dan penyewa bisa memantau lokasi.',
              notificationChannelName: 'Pelacakan Sepeda',
              enableWakeLock: true,
              setOngoing: true,
              color: Color(0xFF0F766E),
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}
