import 'bike.dart';

class RentalHistory {
  const RentalHistory({
    required this.id,
    required this.status,
    required this.totalDistanceMeters,
    required this.distanceCost,
    required this.idleCost,
    required this.totalCost,
    required this.startedAt,
    this.endedAt,
    this.bike,
    this.locationPoints = const [],
  });

  final int id;
  final String status;
  final double totalDistanceMeters;
  final int distanceCost;
  final int idleCost;
  final int totalCost;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Bike? bike;
  final List<RentalLocationPoint> locationPoints;

  double get totalDistanceKilometers => totalDistanceMeters / 1000;

  String get durationString {
    if (endedAt == null) return '-';
    final diff = endedAt!.difference(startedAt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  int get durationMinutes {
    if (endedAt == null) return 0;
    return endedAt!.difference(startedAt).inMinutes;
  }

  double get caloriesBurned {
    // Basic estimation: 8 calories per minute of cycling
    return durationMinutes * 8.0;
  }

  double get averageSpeed {
    // km / hours
    final durationHours = durationMinutes / 60.0;
    if (durationHours == 0) return 0.0;
    return totalDistanceKilometers / durationHours;
  }

  factory RentalHistory.fromJson(Map<String, dynamic> json) {
    return RentalHistory(
      id: json['id'] as int,
      status: json['status'] as String,
      totalDistanceMeters: _toDouble(json['total_distance_meters']) ?? 0,
      distanceCost: _toInt(json['distance_cost']),
      idleCost: _toInt(json['idle_cost']),
      totalCost: _toInt(json['total_cost']),
      startedAt: _toDateTime(json['started_at']) ?? DateTime.now(),
      endedAt: _toDateTime(json['ended_at']),
      bike: json['bike'] == null
          ? null
          : Bike.fromJson(json['bike'] as Map<String, dynamic>),
      locationPoints: json['location_points'] == null
          ? const []
          : (json['location_points'] as List)
              .map((e) => RentalLocationPoint.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class RentalLocationPoint {
  const RentalLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  factory RentalLocationPoint.fromJson(Map<String, dynamic> json) {
    return RentalLocationPoint(
      latitude: _toDouble(json['latitude']) ?? 0.0,
      longitude: _toDouble(json['longitude']) ?? 0.0,
      recordedAt: _toDateTime(json['recorded_at']) ?? DateTime.now(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
