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
      throw Exception('Failed to load notifications');
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
      throw Exception('Failed to mark notification as read');
    }
}
