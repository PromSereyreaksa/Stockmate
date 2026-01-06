import '../../services/database_service.dart';
import '../../models/statistic.dart';

class StockRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> updateStock(String productId, int newQuantity) async {
    final product = await _dbService.getProductById(productId);
    if (product == null) return;

    final oldQuantity = product.currentQuantity;

    await _dbService.updateProductStock(productId, newQuantity);

    await _logStockMovement(
      productId,
      oldQuantity,
      newQuantity,
      newQuantity > oldQuantity ? 'add' : 'remove',
      null,
    );
  }

  Future<void> addStock(String productId, int quantity, String? reason) async {
    final product = await _dbService.getProductById(productId);
    if (product == null) return;

    final newQuantity = product.currentQuantity + quantity;

    await _dbService.updateProductStock(productId, newQuantity);
    await _logStockMovement(
      productId,
      product.currentQuantity,
      newQuantity,
      'add',
      reason,
    );
  }

  Future<void> removeStock(
    String productId,
    int quantity,
    String? reason,
  ) async {
    final product = await _dbService.getProductById(productId);
    if (product == null) return;

    final newQuantity = (product.currentQuantity - quantity).clamp(0, 999999);

    await _dbService.updateProductStock(productId, newQuantity);
    await _logStockMovement(
      productId,
      product.currentQuantity,
      newQuantity,
      'remove',
      reason,
    );
  }

  Future<List<StockMovement>> getStockHistory(String productId) async {
    return await _dbService.getStockHistory(productId);
  }

  Future<void> addStockMovement(
    String productId,
    int previousQty,
    int newQty,
    String changeType,
    String? reason,
    DateTime? timestamp,
  ) async {
    await _logStockMovement(
      productId,
      previousQty,
      newQty,
      changeType,
      reason,
      timestamp,
    );
  }

  Future<bool> needsReorder(String productId) async {
    final product = await _dbService.getProductById(productId);
    if (product == null) return false;

    return product.isLowStock;
  }

  Future<int> getReorderSuggestion(String productId) async {
    final product = await _dbService.getProductById(productId);
    if (product == null) return 0;

    if (product.isLowStock) {
      return (product.minStock * 2) - product.currentQuantity;
    }
    return 0;
  }

  Future<void> bulkUpdateStock(Map<String, int> productQuantities) async {
    for (final entry in productQuantities.entries) {
      await updateStock(entry.key, entry.value);
    }
  }

  Future<void> _logStockMovement(
    String productId,
    int previousQty,
    int newQty,
    String changeType,
    String? reason, [
    DateTime? timestamp,
  ]) async {
    final movement = StockMovement(
      productId: productId,
      previousQty: previousQty,
      newQty: newQty,
      changeType: changeType,
      reason: reason,
      timestamp: timestamp ?? DateTime.now(),
    );
    await _dbService.insertStockMovement(movement);
  }
}
