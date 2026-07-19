import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: ProductModel.fromJson(json['product']),
    quantity: json['quantity'],
  );
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _merchantDeliveryFee = 0.0;
  int? _activeStoreId;
  String? _activeStoreName;
  double? _activeStoreLat;
  double? _activeStoreLng;
  double? _activeStoreRadius;
  String? _appliedPromoCode;
  double _discountAmount = 0.0;

  CartProvider() {
    _loadCachedCart();
  }

  List<CartItem> get items => _items;
  int? get activeStoreId => _activeStoreId;
  String? get activeStoreName => _activeStoreName;
  double? get activeStoreLat => _activeStoreLat;
  double? get activeStoreLng => _activeStoreLng;
  double? get activeStoreRadius => _activeStoreRadius;
  String? get appliedPromoCode => _appliedPromoCode;
  double get discountAmount => _discountAmount;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => _items.isEmpty ? 0.0 : _merchantDeliveryFee;
  
  double get total => (subtotal + deliveryFee - _discountAmount).clamp(0, double.infinity);

  Future<void> _loadCachedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('user_cart');
    if (cartData != null) {
      final decoded = jsonDecode(cartData);
      _activeStoreId = decoded['activeStoreId'];
      _activeStoreName = decoded['activeStoreName'];
      _activeStoreLat = decoded['activeStoreLat'];
      _activeStoreLng = decoded['activeStoreLng'];
      _activeStoreRadius = decoded['activeStoreRadius'];
      _merchantDeliveryFee = decoded['deliveryFee'] ?? 0.0;
      
      final List itemsList = decoded['items'];
      _items.clear();
      _items.addAll(itemsList.map((i) => CartItem.fromJson(i)));
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = jsonEncode({
      'activeStoreId': _activeStoreId,
      'activeStoreName': _activeStoreName,
      'activeStoreLat': _activeStoreLat,
      'activeStoreLng': _activeStoreLng,
      'activeStoreRadius': _activeStoreRadius,
      'deliveryFee': _merchantDeliveryFee,
      'items': _items.map((i) => i.toJson()).toList(),
    });
    await prefs.setString('user_cart', cartData);
  }

  void applyPromo(String code, double discount) {
    _appliedPromoCode = code;
    _discountAmount = discount;
    notifyListeners();
  }

  void removePromo() {
    _appliedPromoCode = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void addToCart(ProductModel product, {double? deliveryFee, String? storeName, double? storeLat, double? storeLng, double? storeRadius}) {
    // If cart has items from another store, we don't add directly. 
    // The UI should handle showing a dialog to clear cart first.
    if (_items.isNotEmpty && _activeStoreId != null && _activeStoreId != product.storeId) {
      return; 
    }

    // If cart is empty, we set the merchant's delivery fee and store ID
    if (_items.isEmpty) {
      _activeStoreId = product.storeId;
      _activeStoreName = storeName;
      _activeStoreLat = storeLat;
      _activeStoreLng = storeLng;
      _activeStoreRadius = storeRadius;
      if (deliveryFee != null) {
        _merchantDeliveryFee = deliveryFee;
      }
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    _saveCart();
    notifyListeners();
  }

  bool isFromDifferentStore(int storeId) {
    return _items.isNotEmpty && _activeStoreId != null && _activeStoreId != storeId;
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
        if (_items.isEmpty) {
          _merchantDeliveryFee = 0.0;
          _activeStoreId = null;
          _activeStoreName = null;
          _activeStoreLat = null;
          _activeStoreLng = null;
          _activeStoreRadius = null;
        }
      } else {
        _items[index].quantity = quantity;
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.isEmpty) {
      _merchantDeliveryFee = 0.0;
      _activeStoreId = null;
      _activeStoreName = null;
      _activeStoreLat = null;
      _activeStoreLng = null;
      _activeStoreRadius = null;
    }
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _merchantDeliveryFee = 0.0;
    _activeStoreId = null;
    _activeStoreName = null;
    _activeStoreLat = null;
    _activeStoreLng = null;
    _activeStoreRadius = null;
    _appliedPromoCode = null;
    _discountAmount = 0.0;
    _saveCart();
    notifyListeners();
  }

  void reorder(List<CartItem> newItems, {double? deliveryFee, String? storeName, int? storeId, double? storeLat, double? storeLng, double? storeRadius}) {
    _items.clear();
    _items.addAll(newItems);
    _activeStoreId = storeId;
    _activeStoreName = storeName;
    _activeStoreLat = storeLat;
    _activeStoreLng = storeLng;
    _activeStoreRadius = storeRadius;
    if (deliveryFee != null) {
      _merchantDeliveryFee = deliveryFee;
    }
    _saveCart();
    notifyListeners();
  }

  // Helper to set delivery fee if fetched separately
  void setDeliveryFee(double fee) {
    _merchantDeliveryFee = fee;
    _saveCart();
    notifyListeners();
  }

  double? getDistanceToStore(double? userLat, double? userLng) {
    if (userLat == null || userLng == null || _activeStoreLat == null || _activeStoreLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      userLat, userLng, _activeStoreLat!, _activeStoreLng!
    ) / 1000;
  }

  bool isOutOfRadius(double? userLat, double? userLng) {
    final dist = getDistanceToStore(userLat, userLng);
    if (dist == null || _activeStoreRadius == null) return false;
    return dist > _activeStoreRadius!;
  }

  void clear() async {
    _items.clear();
    _merchantDeliveryFee = 0.0;
    _activeStoreId = null;
    _activeStoreName = null;
    _activeStoreLat = null;
    _activeStoreLng = null;
    _activeStoreRadius = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cart');
    notifyListeners();
  }
}
