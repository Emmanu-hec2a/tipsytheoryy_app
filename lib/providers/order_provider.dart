import 'package:flutter/material.dart';
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

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/orders/');
      if (response.statusCode == 200) {
        final List data = response.data;
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "Failed to load orders. Please try again.";
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
}
