enum ProductsCategory {
  rice,
  noodles,
  snacks,
  beverages,
  condiments,
  cannedGoods,
  dairy,
  frozen,
  bakery,
  household,
  other
}

class Product {
  String productId;
  String name;
  String description;
  int currentQuantity;
  DateTime expDate;
  int stock;
  int minStock;
  double costPrice;
  double sellingPrice;
  String barcode;
  String brand;
  String supplier;
  String imagePath;
  ProductsCategory category;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.currentQuantity,
    required this.expDate,
    required this.stock,
    required this.minStock,
    required this.costPrice,
    required this.sellingPrice,
    required this.barcode,
    required this.brand,
    required this.supplier,
    required this.imagePath,
    required this.category,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Computed properties
  bool get isLowStock => currentQuantity <= minStock;
  bool get isOutOfStock => currentQuantity == 0;
  bool get isExpiringSoon => expDate.difference(DateTime.now()).inDays <= 7;
  double get profitMargin => sellingPrice - costPrice;

  // Convert Product to Map for database
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'currentQuantity': currentQuantity,
      'expDate': expDate.toIso8601String(),
      'stock': stock,
      'minStock': minStock,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'barcode': barcode,
      'brand': brand,
      'supplier': supplier,
      'imagePath': imagePath,
      'category': category.name,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Product from Map (from database)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId'],
      name: map['name'],
      description: map['description'] ?? '',
      currentQuantity: map['currentQuantity'],
      expDate: DateTime.parse(map['expDate']),
      stock: map['stock'],
      minStock: map['minStock'],
      costPrice: map['costPrice'],
      sellingPrice: map['sellingPrice'],
      barcode: map['barcode'] ?? '',
      brand: map['brand'] ?? '',
      supplier: map['supplier'] ?? '',
      imagePath: map['imagePath'] ?? '',
      category: ProductsCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductsCategory.other,
      ),
      isDeleted: map['isDeleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}