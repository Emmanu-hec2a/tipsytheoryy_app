import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/api_client.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class RiderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Timer? _pollingTimer;

  UserModel? _riderProfile;
  List<OrderModel> _orderQueue = [];
  Map<String, dynamic> _earningsSummary = {};
  bool _isLoading = false;
  String? _error;

  UserModel? get riderProfile => _riderProfile;
  List<OrderModel> get orderQueue => _orderQueue;
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
        _earningsSummary = responses[2].data;
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

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.patch('rider/orders/$orderId/status/', data: {
        'status': newStatus
      });
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
}
