import 'product_model.dart';
import '../core/api_client.dart';

class OrderModel {
  final int id;
  final String orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? customerImage;
  final String? riderName;
  final String? riderImage;
  final String? riderPhone;
  final double? riderRating;
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
  final bool isShiriki;

  // Store / Pickup Info
  final String? storeName;
  final double? storeLatitude;
  final double? storeLongitude;
  final bool requiresRiderVerification;
  final DateTime? riderVerifiedAt;
  final bool hasUnreadMessages;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.customerImage,
    this.riderName,
    this.riderImage,
    this.riderPhone,
    this.riderRating,
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
    this.hasUnreadMessages = false,
    this.items = const [],
    this.isShiriki = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?) ?? [];

    String? cImage = json['customer_image'];
    if (cImage != null && cImage.startsWith('/')) {
      final base = ApiClient.baseUrl.replaceAll('/api/v1/', '');
      cImage = "$base$cImage";
    }

    String? rImage = json['rider_image'];
    if (rImage != null && rImage.startsWith('/')) {
      final base = ApiClient.baseUrl.replaceAll('/api/v1/', '');
      rImage = "$base$rImage";
    }

    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerImage: cImage,
      riderName: json['rider_name'],
      riderImage: rImage,
      riderPhone: json['rider_phone'],
      riderRating: double.tryParse(json['rider_rating']?.toString() ?? ''),
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
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      itemCount: itemsList.length,
      storeName: json['store_name'],
      storeLatitude: double.tryParse(json['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(json['store_longitude']?.toString() ?? ''),
      requiresRiderVerification: json['requires_rider_verification'] ?? false,
      riderVerifiedAt: json['rider_verified_at'] != null ? DateTime.parse(json['rider_verified_at']).toLocal() : null,
      hasUnreadMessages: json['has_unread_messages'] ?? false,
      isShiriki: json['is_shiriki'] ?? false,
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
  final String productName;
  final String? productImage;
  final int quantity;
  final double priceAtOrder;
  final int productId;
  final int storeId;

  OrderItemModel({
    required this.id,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.priceAtOrder,
    required this.productId,
    this.storeId = 0,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productName: json['product_name'] ?? 'Unknown Item',
      productImage: json['product_image'],
      productId: json['food_item'] ?? 0,
      storeId: json['store_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      priceAtOrder: double.tryParse(json['price_at_order']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'product_image': productImage,
      'food_item': productId,
      'store_id': storeId,
      'quantity': quantity,
      'price_at_order': priceAtOrder,
    };
  }
}
