import '../models/product.dart';
import 'products_repository.dart';

class DataSeeder {
  final ProductsRepository _repository = ProductsRepository();

  Future<void> seedInitialData() async {
    final products = await _repository.getAllProducts();
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
        imagePath: 'assets/products/P003.jpg',
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
      await _repository.insertProduct(product);
    }
  }
}
