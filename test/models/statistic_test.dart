import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/models/product.dart';
import 'package:stockmate/models/statistic.dart';

void main() {
  group('Statistics Model Tests', () {
    late List<Product> testProducts;

    setUp(() {
      testProducts = [
        // Product 1: In stock, not expired
        Product(
          productId: 'p1',
          name: 'Product 1',
          description: '',
          currentQuantity: 50,
          expDate: DateTime.now().add(Duration(days: 90)),
          stock: 50,
          minStock: 10,
          costPrice: 5.0,
          sellingPrice: 10.0,
          barcode: '111',
          brand: 'Brand',
          supplier: 'Supplier',
          imagePath: '',
          category: ProductsCategory.snacks,
        ),
        // Product 2: Low stock
        Product(
          productId: 'p2',
          name: 'Product 2',
          description: '',
          currentQuantity: 8,
          expDate: DateTime.now().add(Duration(days: 90)),
          stock: 8,
          minStock: 10,
          costPrice: 3.0,
          sellingPrice: 6.0,
          barcode: '222',
          brand: 'Brand',
          supplier: 'Supplier',
          imagePath: '',
          category: ProductsCategory.beverages,
        ),
        // Product 3: Out of stock
        Product(
          productId: 'p3',
          name: 'Product 3',
          description: '',
          currentQuantity: 0,
          expDate: DateTime.now().add(Duration(days: 90)),
          stock: 0,
          minStock: 5,
          costPrice: 2.0,
          sellingPrice: 4.0,
          barcode: '333',
          brand: 'Brand',
          supplier: 'Supplier',
          imagePath: '',
          category: ProductsCategory.dairy,
        ),
        // Product 4: Deleted (should be excluded)
        Product(
          productId: 'p4',
          name: 'Product 4',
          description: '',
          currentQuantity: 100,
          expDate: DateTime.now().add(Duration(days: 90)),
          stock: 100,
          minStock: 20,
          costPrice: 10.0,
          sellingPrice: 20.0,
          barcode: '444',
          brand: 'Brand',
          supplier: 'Supplier',
          imagePath: '',
          category: ProductsCategory.frozen,
          isDeleted: true,
        ),
      ];
    });

    test('fromProducts should calculate total items correctly (excluding deleted)', () {
      final stats = Statistics.fromProducts(testProducts);
      expect(stats.totalItems, equals(3)); // p1, p2, p3 (p4 is deleted)
    });

    test('fromProducts should count low stock products correctly', () {
      final stats = Statistics.fromProducts(testProducts);
      expect(stats.lowStockCount, equals(2)); // p2 (low), p3 (out of stock)
    });

    test('fromProducts should count out of stock products correctly', () {
      final stats = Statistics.fromProducts(testProducts);
      expect(stats.outOfStockCount, equals(1)); // p3
    });

    test('fromProducts should calculate total value correctly', () {
      final stats = Statistics.fromProducts(testProducts);
      // p1: 50 * 5.0 = 250
      // p2: 8 * 3.0 = 24
      // p3: 0 * 2.0 = 0
      // Total: 274.0
      expect(stats.totalValue, equals(274.0));
    });

    test('fromProducts should calculate estimated profit correctly', () {
      final stats = Statistics.fromProducts(testProducts);
      // p1: 50 * (10.0 - 5.0) = 250
      // p2: 8 * (6.0 - 3.0) = 24
      // p3: 0 * (4.0 - 2.0) = 0
      // Total: 274.0
      expect(stats.estimatedProfit, equals(274.0));
    });

    test('fromProducts should handle empty product list', () {
      final stats = Statistics.fromProducts([]);
      
      expect(stats.totalItems, equals(0));
      expect(stats.lowStockCount, equals(0));
      expect(stats.outOfStockCount, equals(0));
      expect(stats.totalValue, equals(0.0));
      expect(stats.estimatedProfit, equals(0.0));
    });

    test('toMap should convert Statistics to Map correctly', () {
      final stats = Statistics(
        totalItems: 10,
        lowStockCount: 2,
        outOfStockCount: 1,
        totalValue: 500.0,
        estimatedProfit: 250.0,
      );

      final map = stats.toMap();

      expect(map['total_items'], equals(10));
      expect(map['low_stock_count'], equals(2));
      expect(map['out_of_stock_count'], equals(1));
      expect(map['total_value'], equals(500.0));
      expect(map['estimated_profit'], equals(250.0));
    });

    test('fromDb should create Statistics from Map correctly', () {
      final map = {
        'total_items': 15,
        'low_stock_count': 3,
        'out_of_stock_count': 2,
        'total_value': 1000.0,
        'estimated_profit': 500.0,
      };

      final stats = Statistics.fromDb(map);

      expect(stats.totalItems, equals(15));
      expect(stats.lowStockCount, equals(3));
      expect(stats.outOfStockCount, equals(2));
      expect(stats.totalValue, equals(1000.0));
      expect(stats.estimatedProfit, equals(500.0));
    });
  });
}
