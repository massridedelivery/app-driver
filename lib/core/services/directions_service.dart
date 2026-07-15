import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for fetching driving routes from Google Directions API
/// and decoding the encoded polyline string into a list of [LatLng].
class DirectionsService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Loaded from `.env` (GOOGLE_DIRECTIONS_API_KEY) — never hardcode.
  static String get _apiKey => dotenv.env['GOOGLE_DIRECTIONS_API_KEY'] ?? '';

  final Dio _dio;

  DirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches the driving route between [origin] and [destination].
  /// Returns an empty list on failure (network error, API error, etc.)
  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': _apiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') {
        debugPrint('DirectionsService: API returned status=$status');
        return [];
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final overviewPolyline =
          routes[0]['overview_polyline'] as Map<String, dynamic>?;
      final encodedPoints = overviewPolyline?['points'] as String?;

      if (encodedPoints == null || encodedPoints.isEmpty) return [];

      final points = _decodePolyline(encodedPoints);
      debugPrint(
        'DirectionsService: ✅ Decoded ${points.length} polyline points',
      );
      return points;
    } on DioException catch (e) {
      debugPrint('DirectionsService: ❌ DioException: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('DirectionsService: ❌ Unexpected error: $e');
      return [];
    }
  }

  /// Decodes a Google Maps encoded polyline string into a list of [LatLng].
  /// Uses the standard Google polyline encoding algorithm.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
