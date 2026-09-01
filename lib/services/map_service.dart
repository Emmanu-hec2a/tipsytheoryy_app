import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MapService {
  final Dio _dio = Dio();
  final String _googleApiKey = dotenv.env['MAPS_API_KEY'] ?? "";

  /// Fetches a list of LatLng points that follow the road between two coordinates.
  Future<List<LatLng>> getRoutePolylines(LatLng start, LatLng end) async {
    if (_googleApiKey.isEmpty) {
      print("🛑 MapService: Google Maps API Key is missing in .env");
      return [start, end]; // Fallback to straight line
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${start.latitude},${start.longitude}',
          'destination': '${end.latitude},${end.longitude}',
          'key': _googleApiKey,
          'mode': 'driving',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];

          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(
            encodedPolyline,
          );

          return result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          // 🛡️ Better Visibility: Log exactly why Google said no (e.g. REQUEST_DENIED, OVER_QUERY_LIMIT)
          debugPrint(
            "🛑 MapService API Error: ${data['status']} - ${data['error_message'] ?? 'No message'}",
          );
          if (data['status'] == 'REQUEST_DENIED') {
            debugPrint(
              "💡 Tip: Ensure Directions API is enabled for this key in Cloud Console.",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("🛑 MapService Exception: $e");
    }

    return [start, end]; // Fallback to straight line on error
  }
}
