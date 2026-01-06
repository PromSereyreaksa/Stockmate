import '../../services/database_service.dart';
import '../../models/product.dart';
import '../../models/statistic.dart';

class StatisticsRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<Statistics> getStatistics() async {
    return await _dbService.getStatistics();
  }

  Future<List<Product>> getLowStockProducts() async {
    final products = await _dbService.getLowStockProducts();
    return products.where((p) => !p.isOutOfStock).toList()
      ..sort((a, b) => a.currentQuantity.compareTo(b.currentQuantity));
  }

  Future<List<Product>> getOutOfStockProducts() async {
    final products = await _dbService.getAllProducts();
    return products.where((p) => p.isOutOfStock).toList();
  }

  Future<List<Product>> getExpiringSoonProducts() async {
    final products = await _dbService.getAllProducts();
    return products.where((p) => p.isExpiringSoon && !p.isExpired).toList()
      ..sort((a, b) => a.expDate.compareTo(b.expDate));
  }

  Future<List<Product>> getNearlyExpiredProducts() async {
    final products = await _dbService.getAllProducts();
    return products.where((p) => p.isNearlyExpired).toList()
      ..sort((a, b) => a.expDate.compareTo(b.expDate));
  }

  Future<List<Product>> getExpiredProducts() async {
    final products = await _dbService.getAllProducts();
    return products.where((p) => p.isExpired).toList()
      ..sort((a, b) => b.expDate.compareTo(a.expDate));
  }

  Future<Map<String, int>> getProductCounts() async {
    final products = await _dbService.getAllProducts();

    return {
      'total': products.length,
      'lowStock': products.where((p) => p.isLowStock).length,
      'outOfStock': products.where((p) => p.isOutOfStock).length,
      'nearlyExpired': products.where((p) => p.isNearlyExpired).length,
      'expired': products.where((p) => p.isExpired).length,
    };
  }

  Future<double> getTotalInventoryValue() async {
    final products = await _dbService.getAllProducts();

    return products.fold<double>(
      0.0,
      (sum, p) => sum + (p.currentQuantity * p.costPrice),
    );
  }

  Future<double> getTotalPotentialProfit() async {
    final products = await _dbService.getAllProducts();

    return products.fold<double>(
      0.0,
      (sum, p) => sum + (p.currentQuantity * p.profitMargin),
    );
  }
}
