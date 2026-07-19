import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/promotion_model.dart';

class PromotionProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<Promotion> _availablePromotions = [];
  bool _isLoading = false;
  String? _error;

  List<Promotion> get availablePromotions => _availablePromotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPromotions(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('promotions/available/', queryParameters: {
        'store_id': storeId,
      });

      if (response.statusCode == 200) {
        final List data = response.data;
        _availablePromotions = data.map((json) => Promotion.fromJson(json)).toList();
      } else {
        _error = 'Failed to load promotions';
      }
    } catch (e) {
      _error = 'Error: $e';
      print('Promo fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validatePromo(String code, int storeId, double subtotal) async {
    try {
      final response = await _apiClient.post('promotions/validate/', data: {
        'code': code,
        'store_id': storeId,
        'subtotal': subtotal,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'discount_amount': double.parse(response.data['discount_amount'].toString()),
          'title': response.data['title'],
        };
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Invalid promo code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Could not validate promo code. Please try again.',
      };
    }
  }
}
