import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bike.dart';
import '../models/rental.dart' hide RentalLocationPoint;
import '../models/rental_location_point.dart';
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
    defaultValue: 'http://10.200.102.43:9000/api', // Terhubung ke IP Laptop Anda
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

  Future<Map<String, dynamic>> currentUser() async {
    final json = await _get('/auth/me');
    return json['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final json = await _patch(
      '/auth/me',
      body: {'name': name, 'email': email, 'phone': phone},
    );
    final user = json['user'] as Map<String, dynamic>;

    await _sessionStore.updateUser(
      name: user['name'] as String,
      email: user['email'] as String,
    );

    return user;
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _post(
      '/auth/password-reset/request',
      body: {'email': email},
      authenticated: false,
    );
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _post(
      '/auth/password-reset/confirm',
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      authenticated: false,
    );
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

  Future<List<RentalLocationPoint>> rentalLocationPoints(int rentalId) async {
    final json = await _get('/rentals/$rentalId/location-points');
    return (json['data'] as List<dynamic>)
        .map(
          (item) => RentalLocationPoint.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> continueIdle(int rentalId) async {
    await _post('/rentals/$rentalId/idle/continue', body: {});
  }

  Future<Rental> startRentalFromQr(String token) async {
    final json = await _post('/rentals/start-from-qr', body: {'token': token});
    return Rental.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Ambil setting idle dari backend (durasi warning, biaya, interval).
  Future<Map<String, dynamic>> idleSettings() async {
    final json = await _get('/rentals/idle-settings');
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rentalHistory({
    int page = 1,
    int perPage = 10,
  }) async {
    final json = await _get('/rentals/history?page=$page&per_page=$perPage');
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rentalDetail(int rentalId) async {
    final json = await _get('/rentals/$rentalId');
    return json['data'] as Map<String, dynamic>;
  }

  Future<void> deleteRental(int rentalId) async {
    await _delete('/rentals/$rentalId');
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

  Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
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
