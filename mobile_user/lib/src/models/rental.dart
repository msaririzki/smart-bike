import 'bike.dart';

class Rental {
  const Rental({
    required this.id,
    required this.status,
    required this.totalDistanceMeters,
    required this.distanceCost,
    required this.idleCost,
    required this.totalCost,
    this.bike,
    this.startedAt,
    this.currentSpeedKmh = 0,
  });

  final int id;
  final String status;
  final double totalDistanceMeters;
  final int distanceCost;
  final int idleCost;
  final int totalCost;
  final Bike? bike;
  final DateTime? startedAt;
  final double currentSpeedKmh;

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as int,
      status: json['status'] as String,
      totalDistanceMeters: _toDouble(json['total_distance_meters']) ?? 0,
      distanceCost: _toInt(json['distance_cost']),
      idleCost: _toInt(json['idle_cost']),
      totalCost: _toInt(json['total_cost']),
      bike: json['bike'] == null
          ? null
          : Bike.fromJson(json['bike'] as Map<String, dynamic>),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.tryParse(json['started_at'] as String),
      currentSpeedKmh: _toDouble(json['current_speed_kmh']) ?? 0,
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
