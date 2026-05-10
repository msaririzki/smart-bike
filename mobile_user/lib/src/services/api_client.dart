import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bike.dart';
import '../models/rental.dart';
import 'session_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._sessionStore);

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final SessionStore _sessionStore;

  Future<void> login({required String email, required String password}) async {
    final json = await _post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

    await _sessionStore.saveSession(
      token: json['token'] as String,
      name: json['user']['name'] as String,
      email: json['user']['email'] as String,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      authenticated: false,
    );

    await _sessionStore.saveSession(
      token: json['token'] as String,
      name: json['user']['name'] as String,
      email: json['user']['email'] as String,
    );
  }

  Future<void> logout() async {
    await _post('/auth/logout', body: {});
  }

  Future<List<Bike>> bikes() async {
    final json = await _get('/bikes');
    return (json['data'] as List<dynamic>)
        .map((item) => Bike.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Rental?> activeRental() async {
    final json = await _get('/rentals/active');
    final data = json['data'];
    return data == null ? null : Rental.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> activeRentalDetail() async {
    final json = await _get('/rentals/active');
    final data = json['data'];
    return data == null ? null : data as Map<String, dynamic>;
  }

  Future<Rental> startRental(int bikeId) async {
    final json = await _post('/rentals/start', body: {'bike_id': bikeId});
    return Rental.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Rental> finishRental(int rentalId) async {
    final json = await _post('/rentals/$rentalId/finish', body: {});
    return Rental.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> continueIdle(int rentalId) async {
    await _post('/rentals/$rentalId/idle/continue', body: {});
  }

  Future<List<Map<String, dynamic>>> rentalHistory() async {
    final json = await _get('/rentals/history');
    final data = json['data'];

    if (data is Map && data.containsKey('data')) {
      return (data['data'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }

    return (data as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _sessionStore.token;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final json = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final message =
        json['message']?.toString() ??
        (json['errors'] is Map
            ? (json['errors'] as Map).values.first.toString()
            : 'Request gagal.');

    throw ApiException(message, statusCode: response.statusCode);
  }
}
