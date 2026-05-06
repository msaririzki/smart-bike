import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1';
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';

  static Future<RouteResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'bike',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/$profile/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') return null;

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;

      final points = coords.map((c) {
        final pair = c as List<dynamic>;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(
        points: points,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> reverseGeocode(LatLng point) async {
    final url = Uri.parse(
      '$_nominatimUrl/reverse'
      '?lat=${point.latitude}&lon=${point.longitude}'
      '&format=json&zoom=18&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'SmartBikeApp/1.0'},
      );
      if (response.statusCode != 200) return _fallbackLabel(point);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return _fallbackLabel(point);

      final road = address['road'] ?? address['pedestrian'] ?? address['path'];
      final suburb = address['suburb'] ?? address['village'] ?? address['neighbourhood'];

      if (road != null && suburb != null) return '$road, $suburb';
      if (road != null) return road.toString();
      if (suburb != null) return suburb.toString();

      final display = json['display_name'] as String?;
      if (display != null) {
        final parts = display.split(',');
        if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
        return parts[0].trim();
      }

      return _fallbackLabel(point);
    } catch (_) {
      return _fallbackLabel(point);
    }
  }

  static String _fallbackLabel(LatLng point) {
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }
}
