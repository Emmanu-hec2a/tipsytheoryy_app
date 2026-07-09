import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _merchantDeliveryFee = 0.0;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => _items.isEmpty ? 0.0 : _merchantDeliveryFee;
  
  double get total => subtotal + deliveryFee;

  void addToCart(ProductModel product, {double? deliveryFee}) {
    // If cart is empty, we set the merchant's delivery fee from the first product
    if (_items.isEmpty && deliveryFee != null) {
      _merchantDeliveryFee = deliveryFee;
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
        if (_items.isEmpty) _merchantDeliveryFee = 0.0;
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.isEmpty) _merchantDeliveryFee = 0.0;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _merchantDeliveryFee = 0.0;
    notifyListeners();
  }

  // Helper to set delivery fee if fetched separately
  void setDeliveryFee(double fee) {
    _merchantDeliveryFee = fee;
    notifyListeners();
  }
}
