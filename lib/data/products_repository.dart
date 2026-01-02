import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/statistic.dart';
import 'database_helper.dart';

class ProductsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'productId = ? AND isDeleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  // Insert new product
  Future<void> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    product.updatedAt = DateTime.now();
    await db.update(
      'products',
      product.toMap(),
      where: 'productId = ?',
      whereArgs: [product.productId],
    );
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'isDeleted': 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT * FROM products 
      WHERE isDeleted = 0 
      AND currentQuantity <= minStock
      ORDER BY currentQuantity ASC
    ''');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Get expiring products (within 7 days)
  Future<List<Product>> getExpiringProducts() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final sevenDaysLater = now.add(Duration(days: 7));
    
    final maps = await db.query(
      'products',
      where: 'isDeleted = 0 AND expDate <= ?',
      whereArgs: [sevenDaysLater.toIso8601String()],
      orderBy: 'expDate ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'isDeleted = 0 AND (name LIKE ? OR brand LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(ProductsCategory category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'isDeleted = 0 AND category = ?',
      whereArgs: [category.name],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // Update stock quantity
  Future<void> updateStock(String productId, int newQuantity) async {
    final db = await _dbHelper.database;
    
    // Get current quantity first for history
    final product = await getProductById(productId);
    if (product == null) return;
    
    int oldQuantity = product.currentQuantity;
    
    // Update product quantity
    await db.update(
      'products',
      {
        'currentQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'productId = ?',
      whereArgs: [productId],
    );
    
    // Log stock movement
    await _logStockMovement(
      productId,
      oldQuantity,
      newQuantity,
      newQuantity > oldQuantity ? 'add' : 'remove',
      null,
    );
  }

  // Log stock movement (private helper)
  Future<void> _logStockMovement(
    String productId,
    int previousQty,
    int newQty,
    String changeType,
    String? reason,
  ) async {
    final db = await _dbHelper.database;
    await db.insert('stock_movements', {
      'productId': productId,
      'previousQty': previousQty,
      'newQty': newQty,
      'changeType': changeType,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Add stock movement with custom timestamp (for seeding)
  Future<void> addStockMovement(
    String productId,
    int previousQty,
    int newQty,
    String changeType,
    String? reason,
    DateTime? timestamp,
  ) async {
    final db = await _dbHelper.database;
    await db.insert('stock_movements', {
      'productId': productId,
      'previousQty': previousQty,
      'newQty': newQty,
      'changeType': changeType,
      'reason': reason,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    });
  }

  // Get stock movement history for a product
  Future<List<Map<String, dynamic>>> getStockHistory(String productId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'stock_movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
      limit: 20,
    );
  }

  // Get statistics
  Future<Statistics> getStatistics() async {
  final db = await _dbHelper.database;

  final result = await db.rawQuery('''
    SELECT 
      COUNT(*) as total_items,
      SUM(CASE WHEN currentQuantity <= minStock THEN 1 ELSE 0 END) as low_stock_count,
      SUM(CASE WHEN currentQuantity = 0 THEN 1 ELSE 0 END) as out_of_stock_count,
      SUM(currentQuantity * costPrice) as total_value,
      SUM(currentQuantity * (sellingPrice - costPrice)) as estimated_profit
    FROM products
    WHERE isDeleted = 0
  ''');

  return Statistics.fromDb(result.first);
}

}