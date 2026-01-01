class Product {
  final String id;
  final String name;
  final String imagePath;
  final int stock;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.stock,
    this.category,
  });

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock == 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      stock: json['stock'] as int,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'stock': stock,
      'category': category,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? imagePath,
    int? stock,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
      category: category ?? this.category,
    );
  }
}
