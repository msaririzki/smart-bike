import 'bike.dart';

class Rental {
  const Rental({
    required this.id,
    required this.status,
    required this.totalDistanceMeters,
    required this.distanceCost,
    required this.idleCost,
    required this.totalCost,
    this.startedAt,
    this.currentSpeedKmh = 0,
    this.latestLocationPoint,
    this.bike,
  });

  final int id;
  final String status;
  final double totalDistanceMeters;
  final int distanceCost;
  final int idleCost;
  final int totalCost;
  final DateTime? startedAt;
  final double currentSpeedKmh;
  final RentalLocationPoint? latestLocationPoint;
  final Bike? bike;

  double get totalDistanceKilometers => totalDistanceMeters / 1000;

  double? get latitude => bike?.latitude ?? latestLocationPoint?.latitude;

  double? get longitude => bike?.longitude ?? latestLocationPoint?.longitude;

  DateTime? get lastLocationUpdateAt => latestLocationPoint?.recordedAt;

  String? get networkType => latestLocationPoint?.networkType;

  double? get gpsAccuracyMeters => latestLocationPoint?.accuracyMeters;

  factory Rental.fromJson(Map<String, dynamic> json) {
    final latestPoint = json['latest_location_point'];
    final parsedLatestPoint = latestPoint is Map
        ? RentalLocationPoint.fromJson(
            Map<String, dynamic>.from(latestPoint),
          )
        : null;

    return Rental(
      id: json['id'] as int,
      status: json['status'] as String,
      totalDistanceMeters: _toDouble(json['total_distance_meters']) ?? 0,
      distanceCost: _toInt(json['distance_cost']),
      idleCost: _toInt(json['idle_cost']),
      totalCost: _toInt(json['total_cost']),
      startedAt: _toDateTime(json['started_at']),
      currentSpeedKmh:
          _toDouble(json['current_speed_kmh']) ??
          parsedLatestPoint?.speedKmh ??
          0,
      latestLocationPoint: parsedLatestPoint,
      bike: json['bike'] == null
          ? null
          : Bike.fromJson(Map<String, dynamic>.from(json['bike'] as Map)),
    );
  }
}

class RentalLocationPoint {
  const RentalLocationPoint({
    this.latitude,
    this.longitude,
    this.speedKmh,
    this.accuracyMeters,
    this.networkType,
    this.recordedAt,
  });

  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final double? accuracyMeters;
  final String? networkType;
  final DateTime? recordedAt;

  factory RentalLocationPoint.fromJson(Map<String, dynamic> json) {
    return RentalLocationPoint(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      speedKmh: _toDouble(json['speed_kmh']),
      accuracyMeters: _toDouble(json['accuracy_meters']),
      networkType: json['network_type']?.toString(),
      recordedAt: _toDateTime(json['recorded_at']),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}
