import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class RiderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final loc.Location _locationService = loc.Location();
  Timer? _pollingTimer;
  Timer? _locationHeartbeatTimer;
  Position? _lastKnownPosition;

  UserModel? _riderProfile;
  List<OrderModel> _orderQueue = [];
  List<OrderModel> _deliveryHistory = [];
  List<Map<String, dynamic>> _earningsHistory = [];
  List<dynamic> _payoutHistory = []; // 🆕 New Payout Stats
  Map<String, dynamic> _earningsSummary = {};
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _error;

  UserModel? get riderProfile => _riderProfile;
  List<OrderModel> get orderQueue => _orderQueue;
  List<OrderModel> get deliveryHistory => _deliveryHistory;
  List<Map<String, dynamic>> get earningsHistory => _earningsHistory;
  List<dynamic> get payoutHistory => _payoutHistory;
  Map<String, dynamic> get earningsSummary => _earningsSummary;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get error => _error;
  bool get isOnline => _riderProfile?.isAvailable ?? false;

  OrderModel? get activeOrder => _orderQueue.where((o) =>
    ['assigned', 'picked_up', 'arrived'].contains(o.status.toLowerCase())
  ).firstOrNull;

  void startRealtimePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollData();
    });
  }

  void stopRealtimePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _stopLocationHeartbeat();
  }

  void _startLocationHeartbeat() {
    _locationHeartbeatTimer?.cancel();
    _locationHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _pingLocation();
    });
    _pingLocation();
  }

  void _stopLocationHeartbeat() {
    _locationHeartbeatTimer?.cancel();
    _locationHeartbeatTimer = null;
  }

  Future<void> _pollData() async {
    try {
      // 🛡️ Guard: Only poll if the user is actually a rider
      final role = await _storage.read(key: 'role');
      if (role != 'rider') {
        stopRealtimePolling();
        return;
      }

      final response = await _apiClient.get(
        'rider/orders/queue/',
        queryParameters: _lastKnownPosition == null
            ? null
            : {
                'lat': _lastKnownPosition!.latitude,
                'lng': _lastKnownPosition!.longitude,
              },
      );
      if (response.statusCode == 200) {
        final List data = response.data;
        _orderQueue = data.map((json) => OrderModel.fromJson(json)).toList();
        notifyListeners();

        if (activeOrder != null) {
          _pingLocation(orderId: activeOrder!.id);
        }
      }
    } catch (e) {
      debugPrint("Polling error: $e");
    }
  }

  Future<void> _pingLocation({int? orderId}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      _lastKnownPosition = position;
      await _apiClient.post('rider/location/ping/', data: {
        if (orderId != null) 'order_id': orderId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      debugPrint("Location ping error: $e");
    }
  }

  Future<void> fetchRiderData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        _apiClient.get('rider/profile/'),
        _apiClient.get('rider/orders/queue/'),
        _apiClient.get('rider/orders/history/'),
        _apiClient.get('rider/earnings/'),
        _apiClient.get('rider/earnings/summary/'),
      ]);

      if (responses[0].statusCode == 200) {
        _riderProfile = UserModel.fromJson(responses[0].data);
        if (isOnline) {
          _startLocationHeartbeat();
        } else {
          _lastKnownPosition = null;
          _stopLocationHeartbeat();
        }
      }
      if (responses[1].statusCode == 200) {
        final List data = responses[1].data;
        _orderQueue = data.map((json) => OrderModel.fromJson(json)).toList();
      }
      if (responses[2].statusCode == 200) {
        final List data = responses[2].data;
        _deliveryHistory = data.map((json) => OrderModel.fromJson(json)).toList();
      }
      if (responses[3].statusCode == 200) {
        _earningsHistory = List<Map<String, dynamic>>.from(responses[3].data);
      }
      if (responses[4].statusCode == 200) {
        _earningsSummary = responses[4].data;
      }
      
      startRealtimePolling();
    } catch (e) {
      _error = "Failed to load rider data.";
      debugPrint("Rider data error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleAvailability(bool available) async {
    // 🛡️ Optimistic Update: Update UI instantly, but track the old state to revert if needed
    final oldState = _riderProfile?.isAvailable ?? false;
    if (_riderProfile != null) {
      _riderProfile = _riderProfile!.copyWith(isAvailable: available);
      notifyListeners();
    }

    _isActionLoading = true;
    _error = null;

    try {
      Map<String, dynamic> payload = {'is_available': available};

      // 🛰️ Location Guard for Online Toggle
      if (available) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          throw 'Location permissions are required to go online.';
        }

        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // 🪄 MAGIC PROMPT: Request user to turn on GPS without leaving the app
          serviceEnabled = await _locationService.requestService();
          if (!serviceEnabled) {
            throw 'Please turn on your GPS to go online.';
          }
        }

        // Fast-Track Location: Try last known first to avoid "loading for years"
        Position? position = await Geolocator.getLastKnownPosition();
        
        // If no last known, or if it's too old, get current with a strict timeout
        position ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
        );

        _lastKnownPosition = position;
        payload['latitude'] = position.latitude;
        payload['longitude'] = position.longitude;
      }

      final response = await _apiClient.patch('rider/profile/', data: payload);
      if (response.statusCode == 200) {
        _riderProfile = UserModel.fromJson(response.data);
        if (available) {
          _startLocationHeartbeat();
        } else {
          _lastKnownPosition = null;
          _stopLocationHeartbeat();
        }
      }
    } on DioException catch (e) {
      // Revert Optimistic Update
      if (_riderProfile != null) {
        _riderProfile = _riderProfile!.copyWith(isAvailable: oldState);
      }
      
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        _error = (data is Map) ? (data['message'] ?? data['error']) : "Action blocked.";
      } else {
        _error = "Server connection failed.";
      }
      debugPrint("Toggle availability error: $e");
    } catch (e) {
      // Revert Optimistic Update
      if (_riderProfile != null) {
        _riderProfile = _riderProfile!.copyWith(isAvailable: oldState);
      }
      _error = e.toString();
      debugPrint("Toggle availability generic error: $e");
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('rider/orders/$orderId/accept/');
      if (response.statusCode == 200) {
        await _pollData();
        return true;
      }
    } catch (e) {
      debugPrint("Accept order error: $e");
      _error = "Order already taken or connection error.";
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus, {String? verificationMethod, String? imagePath}) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      dynamic data;
      
      if (imagePath != null) {
        // Use FormData for file upload
        data = FormData.fromMap({
          'status': newStatus,
          if (verificationMethod != null) 'verification_method': verificationMethod,
          'verification_image': await MultipartFile.fromFile(imagePath, filename: 'verify.jpg'),
        });
      } else {
        data = {
          'status': newStatus,
          if (verificationMethod != null) 'verification_method': verificationMethod,
        };
      }

      final response = await _apiClient.patch('rider/orders/$orderId/status/', data: data);
      if (response.statusCode == 200) {
        await _pollData();
        return true;
      }
    } catch (e) {
      debugPrint("Update order status error: $e");
      _error = "Failed to update order status.";
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  // 🆕 Payout & Panic Logic
  Future<void> fetchPayoutHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('rider/payouts/history/');
      if (response.statusCode == 200) {
        _payoutHistory = response.data;
      }
    } catch (e) {
      debugPrint("Payout fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> triggerPanic() async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final pos = await Geolocator.getCurrentPosition();
      final response = await _apiClient.post('rider/panic/', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Panic alert error: $e");
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> disputePayout(int payoutId, String reason) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('rider/payouts/$payoutId/dispute/', data: {
        'reason': reason,
      });
      if (response.statusCode == 200) {
        await fetchPayoutHistory();
        return true;
      }
    } catch (e) {
      debugPrint("Dispute error: $e");
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> reportIssue(String message) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('rider/report-issue/', data: {
        'message': message,
        'type': 'General Support'
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Report issue error: $e");
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopRealtimePolling();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    stopRealtimePolling();
    _lastKnownPosition = null;
    _riderProfile = null;
    _orderQueue = [];
    _deliveryHistory = [];
    _earningsHistory = [];
    _earningsSummary = {};
    _error = null;
    notifyListeners();
  }
}
