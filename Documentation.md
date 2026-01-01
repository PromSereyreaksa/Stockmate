# StockMate Development Log
**Developer:** Reaksa  
**Date:** January 1, 2026

---

## Day 1 - Setting Up the Database

Today I migrated StockMate from mock data to a real SQLite database. Here's how everything works now.

### Architecture Overview

I'm following Clean Architecture to keep things organized:

```
lib/
├── models/              # Data models (Product, etc.)
├── data/                # Database layer
│   ├── database_helper.dart
│   ├── products_repository.dart
│   └── data_seeder.dart
└── ui/                  # Screens and widgets
    ├── splash_screen.dart
    ├── home_screen.dart
    └── widgets/
```

### Dependencies I Added

```yaml
sqflite: ^2.3.3                 # SQLite for mobile
sqflite_common_ffi: ^2.3.0      # SQLite for desktop
intl: ^0.19.0                   # Date formatting
window_manager: ^0.5.1          # Lock window size on desktop
```

---

## How the Database Works

### 1. Database Initialization

I created `database_helper.dart` as a singleton. When the app starts, it:
- Checks if database exists
- If not, creates `stockmate.db` with two tables

**Tables:**
- `products` - all product info
- `stock_movements` - history of stock changes

The tricky part was Linux support. I had to explicitly load the SQLite library:
```dart
DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so');
```

**Database location:** `.dart_tool/sqflite_common_ffi/databases/stockmate.db`

### 2. Seeding Initial Data

In `main.dart`, before the app starts, I call:
```dart
await DataSeeder().seedInitialData();
```

This checks if the database is empty. If yes, it inserts 5 chip products (P001-P005). If there's already data, it skips.

---

## How Products Flow Through the App

### Adding a Product (Future Implementation)

When I add the product form screen, here's the flow:

1. User fills form → taps "Add Product"
2. Create Product object with all fields
3. Call `repository.insertProduct(product)`
4. Repository converts to Map and inserts into database
5. UI refreshes to show new product

### Updating Stock (Current Implementation)

When user taps +/- buttons on home screen:

1. User taps button
2. `_updateStock(product, change)` is called
3. Calculate new quantity: `newQuantity = currentQuantity + change`
4. Call `repository.updateStock(productId, newQuantity)`
5. Repository:
   - Gets old quantity
   - Updates product quantity in database
   - Logs change in stock_movements table
6. Refresh UI with `_loadData()`

**Code flow:**
```
UI (+ button) 
  → _updateStock(product, +1)
  → repository.updateStock(id, newQty)
  → UPDATE products SET currentQuantity = ?
  → INSERT into stock_movements
  → _loadData() refreshes screen
```

### Loading Data on Home Screen

When home screen opens:

1. Call `_loadData()` in `initState()`
2. Query repository for:
   - `getStatistics()` → total items, low stock count
   - `getLowStockProducts()` → alerts
   - `getAllProducts()` → recent items (take first 3)
3. Update state variables
4. UI rebuilds with database data

**Query example:**
```dart
final stats = await _repository.getStatistics();
// Returns: {totalItems: 5, lowStockCount: 2, outOfStockCount: 1}
```

---

## Screen Navigation (Current Setup)

Right now I only have:
- Splash Screen (2 seconds) → Home Screen
- Bottom nav bar (placeholders)

**Flow:**
```
Splash → waits 2 seconds → Navigator.pushReplacement(HomeScreen)
```

Bottom nav is ready but other screens not implemented yet.

---

## Product Repository Methods

All database operations go through `products_repository.dart`:

### Read Operations
- `getAllProducts()` - get all products
- `getProductById(id)` - get single product
- `getLowStockProducts()` - where currentQuantity ≤ minStock
- `getExpiringProducts()` - expiring within 7 days
- `searchProducts(query)` - search name/brand/barcode
- `getProductsByCategory(category)` - filter by category
- `getStatistics()` - calculate dashboard stats

### Write Operations
- `insertProduct(product)` - add new product
- `updateProduct(product)` - update existing
- `deleteProduct(id)` - soft delete (sets isDeleted = 1)
- `updateStock(id, quantity)` - update stock + log history

### Stock History
- `getStockHistory(id)` - last 20 movements for a product

---

## Data Flow Example: User Updates Stock

```
1. Home Screen renders Recent Items
   - Shows: Lays Chips | Stock: 15 | [−] 15 [+]

2. User taps [+]
   - Calls: onIncrement: () => _updateStock(product, 1)

3. _updateStock() method
   - Calculate: newQuantity = 15 + 1 = 16
   - Call: await _repository.updateStock('P001', 16)

4. Repository.updateStock()
   - Get current product to save old quantity
   - SQL: UPDATE products SET currentQuantity = 16, updatedAt = now()
   - SQL: INSERT into stock_movements (productId, previousQty, newQty, changeType)

5. _loadData() refreshes
   - Query database again
   - setState() triggers rebuild
   - UI now shows: Stock: 16

6. If stock <= minStock
   - Product appears in Stock Alerts section too
```

---

## Current Limitations

- No product add/edit screens yet
- No product details screen
- No analytics screen
- Bottom nav doesn't navigate (placeholders only)
- Images are hardcoded to assets (no image picker)
- No barcode scanning yet

---

## Next Steps

1. Product List Screen - view all products with filters
2. Product Details Screen - full product info + edit
3. Add Product Screen - form to add new products
4. Analytics Screen - charts and reports
5. Image picker for product photos
6. Barcode scanner integration

---

## Technical Notes

**Why soft delete?**  
I use `isDeleted = 1` instead of actually deleting rows. This way I can keep history and undo if needed.

**Why stock_movements table?**  
Every time stock changes, I log it. Later I can show:
- Who changed it (when I add users)
- When it changed
- What the reason was
- Full audit trail

**Database path:**  
`/home/sou/stockmate/.dart_tool/sqflite_common_ffi/databases/stockmate.db`

Can inspect with: `sqlite3 <path>`

---

That's it for today. Database is working, stock updates persist, and the foundation is solid for adding more features.

— Reaksa

