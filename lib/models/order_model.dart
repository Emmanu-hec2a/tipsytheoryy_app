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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
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
      addressString: json['address_string'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      riderLatitude: double.tryParse(json['rider_latitude']?.toString() ?? ''),
      riderLongitude: double.tryParse(json['rider_longitude']?.toString() ?? ''),
      createdAt: DateTime.parse(json['created_at']),
      itemCount: (json['items'] as List?)?.length ?? 0,
      storeName: json['store_name'],
      storeLatitude: double.tryParse(json['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(json['store_longitude']?.toString() ?? ''),
      requiresRiderVerification: json['requires_rider_verification'] ?? false,
      riderVerifiedAt: json['rider_verified_at'] != null ? DateTime.parse(json['rider_verified_at']) : null,
    );
  }
}
