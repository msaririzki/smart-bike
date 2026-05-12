import 'package:geolocator/geolocator.dart';

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
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    );
  }
}
