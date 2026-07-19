import 'product_model.dart';

class OrderModel {
  final int id;
  final String orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? riderName;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double total;
  final double deliveryFee;
  final String? promoCode;
  final double discountAmount;
  final String? addressString;
  final double? latitude;
  final double? longitude;
  final double? riderLatitude;
  final double? riderLongitude;
  final DateTime createdAt;
  final int itemCount;

  // Store / Pickup Info
  final String? storeName;
  final double? storeLatitude;
  final double? storeLongitude;
  final bool requiresRiderVerification;
  final DateTime? riderVerifiedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.riderName,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod = 'mpesa',
    required this.total,
    this.deliveryFee = 0.0,
    this.promoCode,
    this.discountAmount = 0.0,
    this.addressString,
    this.latitude,
    this.longitude,
    this.riderLatitude,
    this.riderLongitude,
    required this.createdAt,
    required this.itemCount,
    this.storeName,
    this.storeLatitude,
    this.storeLongitude,
    this.requiresRiderVerification = false,
    this.riderVerifiedAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?) ?? [];
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      riderName: json['rider_name'],
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'mpesa',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      promoCode: json['promo_code'],
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      addressString: json['address_string'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      riderLatitude: double.tryParse(json['rider_latitude']?.toString() ?? ''),
      riderLongitude: double.tryParse(json['rider_longitude']?.toString() ?? ''),
      createdAt: DateTime.parse(json['created_at']),
      itemCount: itemsList.length,
      storeName: json['store_name'],
      storeLatitude: double.tryParse(json['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(json['store_longitude']?.toString() ?? ''),
      requiresRiderVerification: json['requires_rider_verification'] ?? false,
      riderVerifiedAt: json['rider_verified_at'] != null ? DateTime.parse(json['rider_verified_at']) : null,
      items: itemsList.map((i) => OrderItemModel.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'rider_name': riderName,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'total': total,
      'delivery_fee': deliveryFee,
      'promo_code': promoCode,
      'discount_amount': discountAmount,
      'address_string': addressString,
      'latitude': latitude,
      'longitude': longitude,
      'rider_latitude': riderLatitude,
      'rider_longitude': riderLongitude,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'store_name': storeName,
      'store_latitude': storeLatitude,
      'store_longitude': storeLongitude,
      'requires_rider_verification': requiresRiderVerification,
      'rider_verified_at': riderVerifiedAt?.toIso8601String(),
    };
  }
}

class OrderItemModel {
  final int id;
  final String productName; // Backend provides this as 'product_name'
  final int quantity;
  final double priceAtOrder;
  final int productId; // Backend field is 'food_item'

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.priceAtOrder,
    required this.productId,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productName: json['product_name'] ?? 'Unknown Item',
      productId: json['food_item'] ?? 0,
      quantity: json['quantity'] ?? 1,
      priceAtOrder: double.tryParse(json['price_at_order']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'food_item': productId,
      'quantity': quantity,
      'price_at_order': priceAtOrder,
    };
  }
}
