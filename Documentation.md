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

**Developer:** Davann
**Date:** January 1, 2026

---

## Day 1 - Database Optimization & Analytics Implementation

Today I refactored the database initialization to be cleaner and built out the full analytics screen with real data visualization.

### Database Initialization Improvement

The old approach used hardcoded library paths which wasn't portable:

```dart
// OLD - hardcoded path
DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so');
```

I replaced it with the FFI (Foreign Function Interface) factory approach in `DatabaseHelper._init()`:

```dart
// NEW - cleaner, platform-agnostic
DatabaseHelper._init() {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
```

This is much better because:
- No hardcoded paths that break on different systems
- The sqflite package handles library loading automatically
- Works across Linux, Windows, and macOS
- More maintainable and portable

### Files Changed

- `lib/data/database_helper.dart` - Refactored `_init()` method

---

## Restructured Navigation

I moved `MainNavigation` from being just in HomeScreen to being the central hub. Now the flow is:

**New Navigation Structure:**
```
Splash Screen (2 seconds)
  ↓ pushReplacement()
MainNavigation (with BottomNavigationBar)
  ├─ Home (HomeScreen)
  ├─ Items (AnalyticsScreen)
  ├─ Add (placeholder)
  └─ Reports (placeholder)
```

The `MainNavigation` widget uses `IndexedStack` to keep all screens loaded while switching which one is visible. This keeps state and makes switching between tabs smooth.

**Updated Architecture:**

```
lib/
├── models/
│   ├── product.dart
│   ├── statistic.dart          # Contains Statistics & StockMovementData models
│   └── stock_summary.dart
├── data/
│   ├── database_helper.dart    # UPDATED: FFI init
│   ├── products_repository.dart
│   └── data_seeder.dart
└── ui/
    ├── navigation/
    │   └── stock_tab.dart
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── main_navigation.dart  # NOW THE CENTRAL HUB
    │   ├── home_screen.dart
    │   └── analytics_screen.dart # NEW: Full implementation
    └── widgets/
        ├── stat_card.dart           # NEW: Metric display cards
        ├── stock_movement_chart.dart # NEW: Line chart visualization
        ├── recent_item_card.dart
        ├── stock_alert_card.dart
        └── summary_card.dart
```

---

## Built Full Analytics Screen

Implemented `AnalyticsScreen` with real database queries and interactive visualizations.

### StatCard Widget

Simple reusable widget that displays key metrics:
- Label (text label)
- Value (main number)
- Icon (with background color)
- Background color (customizable)

**On analytics screen shows:**
- Total Items - count of all products
- Low Stock Count - products below minStock
- Out of Stock Count - currentQuantity = 0
- Total Value - sum of all inventory cost
- Estimated Profit - calculated margin

Each card is clean and scannable.

### StockMovementChart Widget

Interactive line chart showing stock flow over time:
- Uses `fl_chart` package for rendering
- Two lines: Stock In (blue) and Stock Out (red)
- Configurable date range (7, 14, 30 days)
- Aggregates daily totals from stock_movements table
- Shows totals legend below chart

**How it aggregates:**
```
1. Get all products from database
2. For each product, fetch stock_movements history
3. Filter movements by selected date range
4. Group by date and sum daily stock in/out
5. Render as line chart with grid
```

### AnalyticsScreen Data Flow

```dart
_loadData() async {
  1. Query getStatistics()
     → totalItems, lowStockCount, outOfStockCount, totalValue, profit
  
  2. Query getAllProducts()
     → get all product data
  
  3. Call _getStockMovements(days)
     → loop through all products
     → get each product's stock history
     → aggregate by date
     → return StockMovementData list
  
  4. setState() updates UI
     → StatCards render with numbers
     → Chart renders with aggregated data
}
```

### New Models

Updated `models/statistic.dart` with:

```dart
class Statistics {
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValue;
  final double estimatedProfit;
}

class StockMovementData {
  final DateTime date;
  final int stockIn;
  final int stockOut;
}
```

These models handle the analytics data structure and can convert to/from database format.

### Dependencies

Make sure `pubspec.yaml` includes:
```yaml
fl_chart: ^0.65.0  # For chart rendering
```

---

## What's Working

- Database initialization with FFI - clean and portable  
- Main navigation routes all tabs  
- Analytics screen loads real statistics  
- StatCard widgets display metrics cleanly  
- Stock movement chart aggregates daily data  
- Bottom nav switches between Home and Analytics  

## Still To Do

- Add tab to product form
- Implement Reports tab  
- Add filter options to analytics (by category, date range)
- Implement Items/Product List screen
- Connect navigation properly to all screens

That's it for today. Database is cleaner, navigation is more structured, and analytics screen is fully functional with real data.

— Vannie

