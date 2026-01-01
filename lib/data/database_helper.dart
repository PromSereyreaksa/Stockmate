import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:ffi';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    if (Platform.isLinux || Platform.isWindows) {
      if (Platform.isLinux) {
        DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so');
      }
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stockmate.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create tables
  Future<void> _createDB(Database db, int version) async {
    // Products table
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

    // Stock movements table (for history)
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

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_expdate ON products(expDate)');
    await db.execute('CREATE INDEX idx_products_quantity ON products(currentQuantity)');
    await db.execute('CREATE INDEX idx_stock_movements_product ON stock_movements(productId)');
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}