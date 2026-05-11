import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bike.dart';
import '../models/device_rental_summary.dart';
import 'session_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._session);

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final SessionStore _session;

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<void> login({required String email, required String password}) async {
    final json = await _post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    await _session.saveSession(
      token: json['token'] as String,
      name: json['user']['name'] as String,
      email: json['user']['email'] as String,
    );
  }

  Future<void> logout() async {
    await _post('/auth/logout', body: {});
    await _session.clearSession();
  }

  // ─── Device ──────────────────────────────────────────────────────────────

  Future<Bike?> currentAssignment() async {
    final json = await _get('/device/current-assignment');
    final data = json['data'];
    if (data == null) return null;
    return Bike.fromJson(data as Map<String, dynamic>);
  }

  Future<DeviceRentalSummary> activeRentalSummary() async {
    final json = await _get('/device/active-rental-summary');
    final data = json['data'];
    if (data is! Map) return const DeviceRentalSummary();
    return DeviceRentalSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> sendHeartbeat({
    required String networkType,
    required int batteryPercent,
    String? signalNote,
  }) async {
    return _post('/device/heartbeat', body: {
      'network_type': networkType,
      'battery_percent': batteryPercent,
      if (signalNote != null) 'signal_note': signalNote,
    });
  }

  Future<Map<String, dynamic>> sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? accuracyMeters,
    required String networkType,
  }) async {
    return _post('/device/location-update', body: {
      'latitude': latitude,
      'longitude': longitude,
      if (speedKmh != null) 'speed_kmh': speedKmh,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      'network_type': networkType,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final h = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated) {
      final token = await _session.token;
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final json = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final message = json['message']?.toString() ??
        (json['errors'] is Map
            ? (json['errors'] as Map).values.first.toString()
            : 'Request gagal.');

    throw ApiException(message, statusCode: res.statusCode);
  }
}
