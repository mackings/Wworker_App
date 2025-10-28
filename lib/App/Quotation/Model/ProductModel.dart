class ProductModel {
  final String id;
  final String userId;
  final String name;
  final String productId;
  final String category;
  final String subCategory;
  final String description;
  final String image;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.productId,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.image,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["_id"] ?? "",
      userId: json["userId"] ?? "",
      name: json["name"] ?? "",
      productId: json["productId"] ?? "",
      category: json["category"] ?? "",
      subCategory: json["subCategory"] ?? "",
      description: json["description"] ?? "",
      image: json["image"] ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
    );
  }
}
