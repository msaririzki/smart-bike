import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'session_store.dart';
import 'api_client.dart';

class NotificationService {
  Future<List<NotificationData>> getNotifications() async {
    final token = await SessionStore().token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((json) => NotificationData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications (Status: ${response.statusCode}): ${response.body}');
    }
  }

  Future<int> getUnreadCount() async {
    final token = await SessionStore().token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/notifications/unread-count'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['count'] as int;
    } else {
      throw Exception('Failed to load unread count (Status: ${response.statusCode})');
    }
  }

  Future<void> markAsRead(int id) async {
    final token = await SessionStore().token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/notifications/$id/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read (Status: ${response.statusCode})');
    }
  }

  Future<void> markAsUnread(int id) async {
    final token = await SessionStore().token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/notifications/$id/unread'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as unread (Status: ${response.statusCode})');
    }
  }

  Future<void> deleteNotification(int id) async {
    final token = await SessionStore().token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/notifications/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification (Status: ${response.statusCode})');
    }
  }
}
