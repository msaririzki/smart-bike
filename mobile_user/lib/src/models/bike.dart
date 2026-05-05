class Bike {
  const Bike({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.batteryPercent,
  });

  final int id;
  final String code;
  final String name;
  final String status;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final int? batteryPercent;

  bool get isAvailable => status == 'available';

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      isOnline: json['is_online'] as bool? ?? false,
      latitude: _toDouble(json['current_latitude']),
      longitude: _toDouble(json['current_longitude']),
      batteryPercent: json['battery_percent'] as int?,
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
