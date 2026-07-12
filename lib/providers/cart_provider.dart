import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  CartProvider() {
    _loadCachedCart();
  }

  List<CartItem> get items => _items;
  int? get activeStoreId => _activeStoreId;
  String? get activeStoreName => _activeStoreName;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => _items.isEmpty ? 0.0 : _merchantDeliveryFee;
  
  double get total => subtotal + deliveryFee;

  Future<void> _loadCachedCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('user_cart');
    if (cartData != null) {
      final decoded = jsonDecode(cartData);
      _activeStoreId = decoded['activeStoreId'];
      _activeStoreName = decoded['activeStoreName'];
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
      'deliveryFee': _merchantDeliveryFee,
      'items': _items.map((i) => i.toJson()).toList(),
    });
    await prefs.setString('user_cart', cartData);
  }

  void addToCart(ProductModel product, {double? deliveryFee, String? storeName}) {
    // If cart has items from another store, we don't add directly. 
    // The UI should handle showing a dialog to clear cart first.
    if (_items.isNotEmpty && _activeStoreId != null && _activeStoreId != product.storeId) {
      return; 
    }

    // If cart is empty, we set the merchant's delivery fee and store ID
    if (_items.isEmpty) {
      _activeStoreId = product.storeId;
      _activeStoreName = storeName;
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
    }
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _merchantDeliveryFee = 0.0;
    _activeStoreId = null;
    _activeStoreName = null;
    _saveCart();
    notifyListeners();
  }

  // Helper to set delivery fee if fetched separately
  void setDeliveryFee(double fee) {
    _merchantDeliveryFee = fee;
    _saveCart();
    notifyListeners();
  }
}
