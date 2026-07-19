import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- 📦 OFFLINE PERSISTENCE ---

  Future<void> loadCachedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString('cached_orders');
      if (ordersJson != null) {
        final List data = json.decode(ordersJson);
        _orders = data.map((j) => OrderModel.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading cached orders: $e");
    }
  }

  Future<void> _cacheOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(_orders.map((o) => o.toJson()).toList());
      await prefs.setString('cached_orders', jsonString);
    } catch (e) {
      debugPrint("Error caching orders: $e");
    }
  }

  // --- 🌐 API FETCHING ---

  Future<void> fetchOrders() async {
    // 🛡️ Load from cache first for instant UI
    if (_orders.isEmpty) {
      await loadCachedOrders();
    }

    _isLoading = _orders.isEmpty; // Only show spinner if nothing in cache
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/orders/');
      if (response.statusCode == 200) {
        final List data = response.data;
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
        _cacheOrders(); // 💾 Update cache
      }
    } catch (e) {
      // 💡 Polite, helpful error message
      _error = "We're having trouble reaching the server. Please check your internet connection.";
      print("Order fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<OrderModel> getFilteredOrders(String filter) {
    if (filter == 'All') return _orders;
    return _orders.where((o) => o.status.toLowerCase() == filter.toLowerCase()).toList();
  }

  void clear() async {
    _orders = [];
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_orders');
    notifyListeners();
  }
}
