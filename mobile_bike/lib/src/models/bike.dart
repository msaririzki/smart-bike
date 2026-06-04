class Bike {
  Bike({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.isOnline,
    this.batteryPercent,
    this.currentLatitude,
    this.currentLongitude,
    this.lastAccuracy,
    this.lastSeenAt,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      isOnline: (json['is_online'] as bool?) ?? false,
      batteryPercent: json['battery_percent'] as int?,
      currentLatitude: json['current_latitude'] != null
          ? double.tryParse(json['current_latitude'].toString())
          : null,
      currentLongitude: json['current_longitude'] != null
          ? double.tryParse(json['current_longitude'].toString())
          : null,
      lastAccuracy: json['last_accuracy'] != null
          ? double.tryParse(json['last_accuracy'].toString())
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())?.toLocal()
          : null,
    );
  }

  final int id;
  final String code;
  final String name;
  final String status;
  final bool isOnline;
  final int? batteryPercent;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? lastAccuracy;
  final DateTime? lastSeenAt;
}
