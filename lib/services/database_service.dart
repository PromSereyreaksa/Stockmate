import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/statistic.dart';
import '../models/stock_movement.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stockmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      var tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      bool hasImagePath = tableInfo.any((col) => col['name'] == 'imagePath');

      if (!hasImagePath) {
        await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        productId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        currentQuantity INTEGER NOT NULL DEFAULT 0,
        expDate TEXT NOT NULL,
        stock INTEGER NOT NULL,
        minStock INTEGER NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        barcode TEXT,
        brand TEXT,
        supplier TEXT,
        imagePath TEXT,
        category TEXT NOT NULL,
        isDeleted INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT NOT NULL,
        previousQty INTEGER NOT NULL,
        newQty INTEGER NOT NULL,
        changeType TEXT NOT NULL,
        reason TEXT,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (productId) REFERENCES products(productId)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_category ON products(category)',
    );
    await db.execute('CREATE INDEX idx_products_expdate ON products(expDate)');
    await db.execute(
      'CREATE INDEX idx_products_quantity ON products(currentQuantity)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_movements_product ON stock_movements(productId)',
    );
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stockmate.db');

    await deleteDatabase(path);
    _database = null;
    await database;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'productId = ? AND isDeleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );
    return results.isEmpty ? null : Product.fromMap(results.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'productId = ?',
      whereArgs: [product.productId],
    );
  }

  Future<void> softDeleteProduct(String productId) async {
    final db = await database;
    await db.update(
      'products',
      {'isDeleted': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where:
          'isDeleted = 0 AND (name LIKE ? OR brand LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'isDeleted = 0 AND category = ?',
      whereArgs: [category],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM products 
      WHERE isDeleted = 0 
      AND currentQuantity <= minStock
      ORDER BY currentQuantity ASC
    ''');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateProductStock(String productId, int newQuantity) async {
    final db = await database;
    await db.update(
      'products',
      {
        'currentQuantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'productId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> insertStockMovement(StockMovement movement) async {
    final db = await database;
    await db.insert('stock_movements', movement.toMap());
  }

  Future<List<StockMovement>> getStockHistory(String productId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
      limit: 20,
    );
    return maps.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<Statistics> getStatistics() async {
    final products = await getAllProducts();
    return Statistics.fromProducts(products);
  }
}
