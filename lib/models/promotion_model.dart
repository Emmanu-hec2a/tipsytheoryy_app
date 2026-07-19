class Promotion {
  final int id;
  final String title;
  final String description;
  final String code;
  final double? discountPercentage;
  final double? discountAmount;
  final double minOrderAmount;
  final bool isActive;
  final DateTime endDate;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    this.discountPercentage,
    this.discountAmount,
    required this.minOrderAmount,
    required this.isActive,
    required this.endDate,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      discountPercentage: json['discount_percentage'] != null 
          ? double.tryParse(json['discount_percentage'].toString()) 
          : null,
      discountAmount: json['discount_amount'] != null 
          ? double.tryParse(json['discount_amount'].toString()) 
          : null,
      minOrderAmount: double.tryParse(json['min_order_amount'].toString()) ?? 0.0,
      isActive: json['is_active'] ?? false,
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
