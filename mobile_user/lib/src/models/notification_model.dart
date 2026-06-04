class NotificationData {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.data,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(dynamic value) {
      if (value == null) {
        return null;
      }
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return NotificationData(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'pengumuman',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: parseTime(json['created_at']) ?? DateTime.now(),
      startTime: parseTime(json['start_time']),
      endTime: parseTime(json['end_time']),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }
}
