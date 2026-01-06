import '../../services/database_service.dart';
import '../../models/product.dart';

class ProductRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Product>> getAllProducts() async {
    return await _dbService.getAllProducts();
  }

  Future<Product?> getProductById(String id) async {
    return await _dbService.getProductById(id);
  }

  Future<void> createProduct(Product product) async {
    await _dbService.insertProduct(product);
  }

  Future<void> updateProduct(Product product) async {
    final updatedProduct = product..updatedAt = DateTime.now();
    await _dbService.updateProduct(updatedProduct);
  }

  Future<void> deleteProduct(String productId) async {
    await _dbService.softDeleteProduct(productId);
  }

  Future<List<Product>> searchProducts(String query) async {
    return await _dbService.searchProducts(query);
  }

  Future<List<Product>> getProductsByCategory(ProductsCategory category) async {
    return await _dbService.getProductsByCategory(category.name);
  }

  List<Product> filterByStockStatus(List<Product> products, String status) {
    switch (status.toLowerCase()) {
      case 'instock':
        return products.where((p) => !p.isLowStock && !p.isOutOfStock).toList();
      case 'lowstock':
        return products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
      case 'outofstock':
        return products.where((p) => p.isOutOfStock).toList();
      case 'expired':
        return products.where((p) => p.isExpired).toList();
      case 'almostexpired':
        return products.where((p) => p.isNearlyExpired).toList();
      default:
        return products;
    }
  }

  List<Product> sortProducts(List<Product> products, String sortBy) {
    final sorted = List<Product>.from(products);

    switch (sortBy.toLowerCase()) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        sorted.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case 'stock':
        sorted.sort((a, b) => b.currentQuantity.compareTo(a.currentQuantity));
        break;
      case 'expiry':
        sorted.sort((a, b) => a.expDate.compareTo(b.expDate));
        break;
    }

    return sorted;
  }

  Future<List<Product>> getFilteredSortedProducts({
    String? filterBy,
    String? sortBy,
  }) async {
    var products = await getAllProducts();

    if (filterBy != null) {
      products = filterByStockStatus(products, filterBy);
    }

    if (sortBy != null) {
      products = sortProducts(products, sortBy);
    }

    return products;
  }
}
