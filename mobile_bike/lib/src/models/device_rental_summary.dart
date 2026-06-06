import 'bike.dart';

class DeviceRentalSummary {
  const DeviceRentalSummary({
    this.bike,
    this.rental,
    this.settings,
  });

  final Bike? bike;
  final ActiveBikeRental? rental;
  final DeviceRentalSettings? settings;

  factory DeviceRentalSummary.fromJson(Map<String, dynamic> json) {
    final bikeJson = json['bike'];
    final rentalJson = json['rental'];
    final settingsJson = json['settings'];

    return DeviceRentalSummary(
      bike: bikeJson is Map
          ? Bike.fromJson(Map<String, dynamic>.from(bikeJson))
          : null,
      rental: rentalJson is Map
          ? ActiveBikeRental.fromJson(Map<String, dynamic>.from(rentalJson))
          : null,
      settings: settingsJson is Map
          ? DeviceRentalSettings.fromJson(
              Map<String, dynamic>.from(settingsJson),
            )
          : null,
    );
  }
}

class DeviceRentalSettings {
  const DeviceRentalSettings({
    this.maxReasonableSpeedKmh,
  });

  final double? maxReasonableSpeedKmh;

  factory DeviceRentalSettings.fromJson(Map<String, dynamic> json) {
    return DeviceRentalSettings(
      maxReasonableSpeedKmh: _toDouble(json['max_reasonable_speed_kmh']),
    );
  }
}

class ActiveBikeRental {
  const ActiveBikeRental({
    required this.id,
    required this.status,
    required this.totalDistanceMeters,
    required this.distanceCost,
    required this.idleCost,
    required this.totalCost,
    this.startedAt,
    this.currentSpeedKmh,
    this.user,
    this.latestLocationPoint,
  });

  final int id;
  final String status;
  final double totalDistanceMeters;
  final int distanceCost;
  final int idleCost;
  final int totalCost;
  final DateTime? startedAt;
  final double? currentSpeedKmh;
  final RentalUser? user;
  final BikeLocationPoint? latestLocationPoint;

  double get totalDistanceKilometers => totalDistanceMeters / 1000;

  factory ActiveBikeRental.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final pointJson = json['latest_location_point'];

    return ActiveBikeRental(
      id: _toInt(json['id']),
      status: json['status']?.toString() ?? 'unknown',
      totalDistanceMeters: _toDouble(json['total_distance_meters']) ?? 0,
      distanceCost: _toInt(json['distance_cost']),
      idleCost: _toInt(json['idle_cost']),
      totalCost: _toInt(json['total_cost']),
      startedAt: _toDateTime(json['started_at']),
      currentSpeedKmh: _toDouble(json['current_speed_kmh']),
      user: userJson is Map
          ? RentalUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
      latestLocationPoint: pointJson is Map
          ? BikeLocationPoint.fromJson(Map<String, dynamic>.from(pointJson))
          : null,
    );
  }
}

class RentalUser {
  const RentalUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;

  factory RentalUser.fromJson(Map<String, dynamic> json) {
    return RentalUser(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
    );
  }
}

class BikeLocationPoint {
  const BikeLocationPoint({
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

  factory BikeLocationPoint.fromJson(Map<String, dynamic> json) {
    return BikeLocationPoint(
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
