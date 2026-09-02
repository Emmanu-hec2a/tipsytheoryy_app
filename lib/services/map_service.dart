import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class MapService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches a list of LatLng points that follow the road between two coordinates.
  ///
  /// 🛡️ Routed through our backend (/directions/) instead of calling
  /// Google Directions API directly. The Maps SDK key shipped in the app is
  /// restricted to Android apps (correct for the SDK) and cannot be used for
  /// direct REST calls; the backend holds a separate Directions-only key
  /// that never ships in the client.
  Future<List<LatLng>> getRoutePolylines(LatLng start, LatLng end) async {
    try {
      final response = await _apiClient.get(
        'directions/',
        queryParameters: {
          'origin_lat': start.latitude,
          'origin_lng': start.longitude,
          'dest_lat': end.latitude,
          'dest_lng': end.longitude,
        },
        noCache: true,
      );

      final data = response.data;
      if (data is Map && data['success'] == true && data['polyline'] != null) {
        final PolylinePoints polylinePoints = PolylinePoints();
        final List<PointLatLng> result = polylinePoints.decodePolyline(
          data['polyline'] as String,
        );
        return result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
      debugPrint("🛑 MapService: Backend returned no route: ${data['message']}");
    } catch (e) {
      debugPrint("🛑 MapService Exception: $e");
    }

    return [start, end]; // Fallback to straight line on error
  }
}
