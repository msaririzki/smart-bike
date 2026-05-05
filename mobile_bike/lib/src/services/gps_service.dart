import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsService {
  /// Minta izin GPS. Return true jika diizinkan.
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Ambil posisi sekali.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream posisi real-time tiap [intervalSeconds] detik.
  Stream<Position> positionStream({int intervalSeconds = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: Duration(seconds: intervalSeconds * 4),
      ),
    );
  }
}
