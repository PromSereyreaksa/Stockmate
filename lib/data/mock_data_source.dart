import '../models/product.dart';
import '../models/stock_summary.dart';

class MockDataSource {
  static List<Product> getProducts() {
    return [
      Product(
        id: 'P001',
        name: 'Coca Cola 330ml',
        imagePath: 'assets/products/P001.png',
        stock: 15,
        category: 'Beverages',
      ),
      Product(
        id: 'P002',
        name: 'Lays Chips 50g',
        imagePath: 'assets/products/P002.png',
        stock: 3,
        category: 'Snacks',
      ),
      Product(
        id: 'P003',
        name: 'Bottled Water 500ml',
        imagePath: 'assets/products/P003.jpg',
        stock: 25,
        category: 'Beverages',
      ),
      Product(
        id: 'P004',
        name: 'Instant Noodles',
        imagePath: 'assets/products/P004.png',
        stock: 0,
        category: 'Food',
      ),
      Product(
        id: 'P005',
        name: 'Energy Drink 250ml',
        imagePath: 'assets/products/P005.png',
        stock: 8,
        category: 'Beverages',
      ),
    ];
  }

  static List<Product> getStockAlerts() {
    final products = getProducts();
    return products.where((p) => p.isLowStock || p.isOutOfStock).toList();
  }

  static List<Product> getRecentItems() {
    return getProducts().take(3).toList();
  }

  static StockSummary getStockSummary() {
    final products = getProducts();
    final totalItems = products.length;
    final lowStockCount = products.where((p) => p.isLowStock).length;

    return StockSummary(
      totalItems: totalItems,
      lowStockCount: lowStockCount,
    );
  }
}
