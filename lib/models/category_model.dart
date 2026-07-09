class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final String storeType;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.storeType,
    this.order = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      icon: json['icon'],
      storeType: json['store_type'] ?? 'liquor',
      order: json['order'] ?? 0,
    );
  }
}
