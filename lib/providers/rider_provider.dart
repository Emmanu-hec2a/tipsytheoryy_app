import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class RiderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _pollingTimer;

  UserModel? _riderProfile;
  List<OrderModel> _orderQueue = [];
  List<OrderModel> _deliveryHistory = [];
  List<Map<String, dynamic>> _earningsHistory = [];
  Map<String, dynamic> _earningsSummary = {};
  bool _isLoading = false;
  String? _error;

  UserModel? get riderProfile => _riderProfile;
  List<OrderModel> get orderQueue => _orderQueue;
  List<OrderModel> get deliveryHistory => _deliveryHistory;
  List<Map<String, dynamic>> get earningsHistory => _earningsHistory;
  Map<String, dynamic> get earningsSummary => _earningsSummary;
  bool get isLoading => _isLoading;
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
  }

  Future<void> _pollData() async {
    try {
      // 🛡️ Guard: Only poll if the user is actually a rider
      final role = await _storage.read(key: 'role');
      if (role != 'rider') {
        stopRealtimePolling();
        return;
      }

      final response = await _apiClient.get('rider/orders/queue/');
      if (response.statusCode == 200) {
        final List data = response.data;
        _orderQueue = data.map((json) => OrderModel.fromJson(json)).toList();
        notifyListeners();

        if (activeOrder != null) {
          _pingLocation(activeOrder!.id);
        }
      }
    } catch (e) {
      debugPrint("Polling error: $e");
    }
  }

  Future<void> _pingLocation(int orderId) async {
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
      await _apiClient.post('rider/location/ping/', data: {
        'order_id': orderId,
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
    try {
      final response = await _apiClient.patch('rider/profile/', data: {
        'is_available': available
      });
      if (response.statusCode == 200) {
        _riderProfile = UserModel.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Toggle availability error: $e");
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus, {String? verificationMethod, String? imagePath}) async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    stopRealtimePolling();
    super.dispose();
  }

  void clear() {
    stopRealtimePolling();
    _riderProfile = null;
    _orderQueue = [];
    _deliveryHistory = [];
    _earningsHistory = [];
    _earningsSummary = {};
    _error = null;
    notifyListeners();
  }
}
