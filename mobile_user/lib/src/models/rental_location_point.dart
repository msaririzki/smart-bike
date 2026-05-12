import 'package:latlong2/latlong.dart';

/// A single GPS location point recorded during a rental,
/// sent by the bike device (mobile_bike) via the backend.
class RentalLocationPoint {
  const RentalLocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.accuracyMeters,
    this.recordedAt,
  });

  final int id;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final double? accuracyMeters;
  final DateTime? recordedAt;

  LatLng get latLng => LatLng(latitude, longitude);

  factory RentalLocationPoint.fromJson(Map<String, dynamic> json) {
    return RentalLocationPoint(
      id: json['id'] as int,
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      speedKmh: _toDouble(json['speed_kmh']),
      accuracyMeters: _toDouble(json['accuracy_meters']),
      recordedAt: json['recorded_at'] == null
          ? null
          : DateTime.tryParse(json['recorded_at'] as String),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
