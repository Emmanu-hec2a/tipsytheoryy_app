class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final int? discountPercent;
  final String? image;
  final String? category;
  final int storeId;
  final bool isNewArrival;
  final bool isFeatured;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.image,
    this.category,
    required this.storeId,
    this.isNewArrival = false,
    this.isFeatured = false,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      discountPercent: json['discount_percent'],
      image: json['image'],
      category: json['category_name'] ?? json['category'],
      storeId: json['store'] ?? 0,
      isNewArrival: json['is_new_arrival'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'discount_percent': discountPercent,
      'image': image,
      'category': category,
      'store': storeId,
      'is_new_arrival': isNewArrival,
      'is_featured': isFeatured,
      'is_available': isAvailable,
    };
  }
}
