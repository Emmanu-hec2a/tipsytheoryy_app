class StoreModel {
  final int id;
  final String name;
  final String? shopName;
  final String? logo;
  final String? coverImage;
  final String? tagline;
  final String primaryColor;
  final double rating;
  final int reviewsCount;
  final double deliveryFee;
  final double dynamicDeliveryFee;
  final String deliveryTime;
  final double distance;
  final double latitude;
  final double longitude;
  final bool isFavourite;
  final bool isPro;
  final String? openingTime;
  final String? closingTime;
  final bool isOpen;
  final String? phone;
  final String? addressString;

  StoreModel({
    required this.id,
    required this.name,
    this.shopName,
    this.logo,
    this.coverImage,
    this.tagline,
    required this.primaryColor,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryFee,
    this.dynamicDeliveryFee = 0.0,
    required this.deliveryTime,
    required this.distance,
    required this.latitude,
    required this.longitude,
    this.isFavourite = false,
    this.isPro = false,
    this.openingTime,
    this.closingTime,
    this.isOpen = true,
    this.phone,
    this.addressString,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      name: json['name'],
      shopName: json['shop_name'],
      logo: json['logo'],
      coverImage: json['cover_image'],
      tagline: json['tagline'],
      primaryColor: json['primary_color'] ?? '#0D3B30',
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      reviewsCount: json['rating_count'] ?? 0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0.0') ?? 0.0,
      dynamicDeliveryFee: double.tryParse(json['dynamic_delivery_fee']?.toString() ?? '0.0') ?? 0.0,
      deliveryTime: '${json['avg_delivery_minutes'] ?? 30} mins',
      distance: double.tryParse(json['distance']?.toString() ?? '0.0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      isFavourite: json['is_favourite'] ?? false,
      isPro: json['is_pro'] ?? false,
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      isOpen: json['is_open'] ?? true,
      phone: json['phone'],
      addressString: json['address_string'],
    );
  }
}
