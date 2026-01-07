import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/models/product.dart';

void main() {
  group('Product Model Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = Product(
        productId: 'test-001',
        name: 'Test Product',
        description: 'A test product',
        currentQuantity: 50,
        expDate: DateTime.now().add(Duration(days: 60)),
        stock: 50,
        minStock: 10,
        costPrice: 5.0,
        sellingPrice: 10.0,
        barcode: '123456789',
        brand: 'TestBrand',
        supplier: 'TestSupplier',
        imagePath: '',
        category: ProductsCategory.other,
      );
    });

    test('isLowStock should return true when currentQuantity <= minStock', () {
      testProduct.currentQuantity = 10;
      expect(testProduct.isLowStock, isTrue);

      testProduct.currentQuantity = 5;
      expect(testProduct.isLowStock, isTrue);
    });

    test('isLowStock should return false when currentQuantity > minStock', () {
      testProduct.currentQuantity = 15;
      expect(testProduct.isLowStock, isFalse);
    });

    test('isOutOfStock should return true when currentQuantity is 0', () {
      testProduct.currentQuantity = 0;
      expect(testProduct.isOutOfStock, isTrue);
    });

    test('isOutOfStock should return false when currentQuantity > 0', () {
      testProduct.currentQuantity = 1;
      expect(testProduct.isOutOfStock, isFalse);
    });

    test('isExpired should return true when expDate is in the past', () {
      testProduct.expDate = DateTime.now().subtract(Duration(days: 1));
      expect(testProduct.isExpired, isTrue);
    });

    test('isExpired should return false when expDate is in the future', () {
      testProduct.expDate = DateTime.now().add(Duration(days: 1));
      expect(testProduct.isExpired, isFalse);
    });

    test('isExpiringSoon should return true when expDate is within 7 days', () {
      testProduct.expDate = DateTime.now().add(Duration(days: 5));
      expect(testProduct.isExpiringSoon, isTrue);
    });

    test('isExpiringSoon should return false when expDate is more than 7 days away', () {
      testProduct.expDate = DateTime.now().add(Duration(days: 10));
      expect(testProduct.isExpiringSoon, isFalse);
    });

    test('isNearlyExpired should return true when expDate is within 30 days', () {
      testProduct.expDate = DateTime.now().add(Duration(days: 20));
      expect(testProduct.isNearlyExpired, isTrue);
    });

    test('isNearlyExpired should return false when expDate is more than 30 days away', () {
      testProduct.expDate = DateTime.now().add(Duration(days: 35));
      expect(testProduct.isNearlyExpired, isFalse);
    });

    test('profitMargin should calculate correctly', () {
      expect(testProduct.profitMargin, equals(5.0));
    });

    test('toMap should convert Product to Map correctly', () {
      final map = testProduct.toMap();
      
      expect(map['productId'], equals('test-001'));
      expect(map['name'], equals('Test Product'));
      expect(map['currentQuantity'], equals(50));
      expect(map['costPrice'], equals(5.0));
      expect(map['sellingPrice'], equals(10.0));
      expect(map['category'], equals('other'));
      expect(map['isDeleted'], equals(0));
    });

    test('fromMap should create Product from Map correctly', () {
      final map = {
        'productId': 'test-002',
        'name': 'Mapped Product',
        'description': 'Description',
        'currentQuantity': 25,
        'expDate': DateTime.now().toIso8601String(),
        'stock': 25,
        'minStock': 5,
        'costPrice': 3.0,
        'sellingPrice': 7.0,
        'barcode': '987654321',
        'brand': 'Brand',
        'supplier': 'Supplier',
        'imagePath': '',
        'category': 'snacks',
        'isDeleted': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final product = Product.fromMap(map);

      expect(product.productId, equals('test-002'));
      expect(product.name, equals('Mapped Product'));
      expect(product.currentQuantity, equals(25));
      expect(product.category, equals(ProductsCategory.snacks));
      expect(product.isDeleted, isFalse);
    });
  });
}
