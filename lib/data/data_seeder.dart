import '../models/product.dart';
import 'repositories/product_repository.dart';
import 'repositories/stock_repository.dart';

class DataSeeder {
  final ProductRepository _productRepo = ProductRepository();
  final StockRepository _stockRepo = StockRepository();

  Future<void> seedInitialData() async {
    final products = await _productRepo.getAllProducts();
    if (products.isNotEmpty) return;

    final initialProducts = [
      Product(
        productId: 'P001',
        name: 'Lays Classic Chips 50g',
        description: 'Classic salted potato chips',
        imagePath: 'assets/products/P001.png',
        currentQuantity: 15,
        stock: 50,
        minStock: 10,
        costPrice: 0.30,
        sellingPrice: 0.50,
        barcode: '8850100221012',
        brand: 'Lays',
        supplier: 'PepsiCo',
        category: ProductsCategory.snacks,
        expDate: DateTime(2026, 6, 15),
      ),
      Product(
        productId: 'P002',
        name: 'Pringles Original 40g',
        description: 'Original flavored potato crisps',
        imagePath: 'assets/products/P002.png',
        currentQuantity: 3,
        stock: 30,
        minStock: 5,
        costPrice: 0.40,
        sellingPrice: 0.70,
        barcode: '8850100221029',
        brand: 'Pringles',
        supplier: 'Kelloggs',
        category: ProductsCategory.snacks,
        expDate: DateTime(2026, 5, 20),
      ),
      Product(
        productId: 'P003',
        name: 'Doritos Nacho Cheese 48g',
        description: 'Nacho cheese flavored tortilla chips',
        imagePath: 'assets/products/P003.png',
        currentQuantity: 25,
        stock: 60,
        minStock: 15,
        costPrice: 0.35,
        sellingPrice: 0.60,
        barcode: '8850100221036',
        brand: 'Doritos',
        supplier: 'PepsiCo',
        category: ProductsCategory.snacks,
        expDate: DateTime(2026, 7, 10),
      ),
      Product(
        productId: 'P004',
        name: 'Cheetos Crunchy 35g',
        description: 'Crunchy cheese flavored snacks',
        imagePath: 'assets/products/P004.png',
        currentQuantity: 0,
        stock: 40,
        minStock: 8,
        costPrice: 0.28,
        sellingPrice: 0.48,
        barcode: '8850100221043',
        brand: 'Cheetos',
        supplier: 'PepsiCo',
        category: ProductsCategory.snacks,
        expDate: DateTime(2026, 4, 30),
      ),
      Product(
        productId: 'P005',
        name: 'Ruffles Sour Cream 50g',
        description: 'Sour cream and onion flavored chips',
        imagePath: 'assets/products/P005.png',
        currentQuantity: 8,
        stock: 45,
        minStock: 12,
        costPrice: 0.32,
        sellingPrice: 0.55,
        barcode: '8850100221050',
        brand: 'Ruffles',
        supplier: 'PepsiCo',
        category: ProductsCategory.snacks,
        expDate: DateTime(2026, 5, 25),
      ),
    ];

    for (var product in initialProducts) {
      await _productRepo.createProduct(product);
    }
    
    // Seed some stock movement history for the last 7 days
    await _seedStockMovements();
  }
  
  Future<void> _seedStockMovements() async {
    final now = DateTime.now();
    
    // Sample stock movements over the past 7 days
    final movements = [
      // Day 1 - 7 days ago
      {'productId': 'P001', 'prevQty': 0, 'newQty': 50, 'type': 'add', 'daysAgo': 7},
      {'productId': 'P002', 'prevQty': 0, 'newQty': 30, 'type': 'add', 'daysAgo': 7},
      {'productId': 'P003', 'prevQty': 0, 'newQty': 60, 'type': 'add', 'daysAgo': 7},
      
      // Day 2 - 6 days ago
      {'productId': 'P004', 'prevQty': 0, 'newQty': 40, 'type': 'add', 'daysAgo': 6},
      {'productId': 'P005', 'prevQty': 0, 'newQty': 45, 'type': 'add', 'daysAgo': 6},
      
      // Day 3 - 5 days ago
      {'productId': 'P001', 'prevQty': 50, 'newQty': 45, 'type': 'remove', 'daysAgo': 5},
      {'productId': 'P002', 'prevQty': 30, 'newQty': 25, 'type': 'remove', 'daysAgo': 5},
      
      // Day 4 - 4 days ago
      {'productId': 'P003', 'prevQty': 60, 'newQty': 50, 'type': 'remove', 'daysAgo': 4},
      {'productId': 'P004', 'prevQty': 40, 'newQty': 30, 'type': 'remove', 'daysAgo': 4},
      
      // Day 5 - 3 days ago
      {'productId': 'P001', 'prevQty': 45, 'newQty': 35, 'type': 'remove', 'daysAgo': 3},
      {'productId': 'P005', 'prevQty': 45, 'newQty': 35, 'type': 'remove', 'daysAgo': 3},
      
      // Day 6 - 2 days ago
      {'productId': 'P002', 'prevQty': 25, 'newQty': 20, 'type': 'remove', 'daysAgo': 2},
      {'productId': 'P003', 'prevQty': 50, 'newQty': 40, 'type': 'remove', 'daysAgo': 2},
      
      // Day 7 - 1 day ago
      {'productId': 'P001', 'prevQty': 35, 'newQty': 25, 'type': 'remove', 'daysAgo': 1},
      {'productId': 'P004', 'prevQty': 30, 'newQty': 20, 'type': 'remove', 'daysAgo': 1},
      
      // Today
      {'productId': 'P002', 'prevQty': 20, 'newQty': 15, 'type': 'remove', 'daysAgo': 0},
      {'productId': 'P003', 'prevQty': 40, 'newQty': 35, 'type': 'remove', 'daysAgo': 0},
    ];
    
    for (var movement in movements) {
      final timestamp = now.subtract(Duration(days: movement['daysAgo'] as int));
      await _stockRepo.addStockMovement(
        movement['productId'] as String,
        movement['prevQty'] as int,
        movement['newQty'] as int,
        movement['type'] as String,
        'Initial stock setup',
        timestamp,
      );
    }
  }
}
