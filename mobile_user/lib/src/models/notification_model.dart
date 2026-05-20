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
    // Parse time directly without toLocal if it represents local time, or remove Z if Laravel appends it incorrectly
    DateTime parseTime(String t) {
      if (t.endsWith('Z')) t = t.substring(0, t.length - 1);
      return DateTime.parse(t);
    }
    
    return NotificationData(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'pengumuman',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null 
          ? parseTime(json['created_at']) 
          : DateTime.now(),
      startTime: json['start_time'] != null ? parseTime(json['start_time']) : null,
      endTime: json['end_time'] != null ? parseTime(json['end_time']) : null,
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
