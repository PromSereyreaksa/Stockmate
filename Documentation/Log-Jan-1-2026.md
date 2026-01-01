# StockMate Development Log
**Developer:** Reaksa  
**Date:** January 1, 2026

---

## What I Built Today

Set up StockMate from scratch - created the UI, hooked up SQLite database, and made everything work together.

---

## Project Structure

```
lib/
├── models/
│   └── product.dart           # Product data model
├── data/
│   ├── database_helper.dart   # SQLite setup
│   ├── products_repository.dart
│   └── data_seeder.dart       # Initial data
└── ui/
    ├── splash_screen.dart
    ├── home_screen.dart
    └── widgets/
        ├── summary_card.dart
        ├── stock_alert_card.dart
        └── recent_item_card.dart
```

---

## Dependencies

```yaml
sqflite: ^2.3.3                # Database
sqflite_common_ffi: ^2.3.0     # Desktop support
intl: ^0.19.0                  # Date formatting
window_manager: ^0.5.1         # Lock to mobile size
```

---

## How It Works

### 1. App Startup

**main.dart** → Seeds database → Shows splash screen → Navigates to home

```dart
void main() async {
  await DataSeeder().seedInitialData();  // Add 5 chips if DB empty
  runApp(MyApp());
}
```

### 2. Splash Screen (2 seconds)

Blue screen with StockMate logo → Auto navigates to home

```dart
Timer(Duration(seconds: 2), () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => HomeScreen()),
  );
});
```

### 3. Screen Navigation

**Current Setup:**
- Splash → Home (via `Navigator.pushReplacement` - can't go back)
- Bottom nav has 4 tabs but only Home works right now

**Bottom Nav Structure:**
```dart
int _selectedIndex = 0;

void _onNavigationTapped(int index) {
  setState(() => _selectedIndex = index);
  // Will navigate when screens are built
}

Items: Home | Items | Add | Reports
```

When I build other screens, I'll use:
```dart
Navigator.push(context, MaterialPageRoute(builder: (context) => ItemsScreen()));
```

### 4. Home Screen

Shows:
- App header card
- Summary cards (Total Items, Low Stock count)
- Stock Alerts (products at/below min stock)
- Recent Items (last 3 products with +/- buttons)
- Bottom nav bar

**Data loading:**
```dart
_loadData() async {
  stats = await repository.getStatistics();
  alerts = await repository.getLowStockProducts();
  recentItems = await repository.getAllProducts().take(3);
  setState(() => _isLoading = false);
}
```

### 5. How Stock Updates Work

**Step-by-step when user taps + button:**

1. **UI Button Press**
   ```dart
   IconButton(
     onPressed: () => _updateStock(product, 1),  // +1
     icon: Icon(Icons.add_circle_outline),
   )
   ```

2. **Calculate New Quantity**
   ```dart
   Future<void> _updateStock(Product product, int change) async {
     final newQuantity = (product.currentQuantity + change).clamp(0, 999);
     await _repository.updateStock(product.productId, newQuantity);
     _loadData();  // Refresh
   }
   ```

3. **Repository Updates Database**
   ```dart
   updateStock(String productId, int newQuantity) async {
     // Get old quantity first
     final product = await getProductById(productId);
     int oldQuantity = product.currentQuantity;
     
     // Update product
     await db.update('products', {
       'currentQuantity': newQuantity,
       'updatedAt': DateTime.now().toIso8601String(),
     });
     
     // Log the change
     await db.insert('stock_movements', {
       'productId': productId,
       'previousQty': oldQuantity,
       'newQty': newQuantity,
       'changeType': newQuantity > oldQuantity ? 'add' : 'remove',
     });
   }
   ```

4. **UI Refreshes**
   - `_loadData()` queries database again
   - `setState()` triggers rebuild
   - Updated numbers appear on screen

### 6. How "Recent" Products Are Detected

**Simple approach:** Products sorted by `updatedAt` timestamp

```dart
getAllProducts() async {
  final maps = await db.query(
    'products',
    where: 'isDeleted = 0',
    orderBy: 'updatedAt DESC',  // Most recent first
  );
  return maps.map((map) => Product.fromMap(map)).toList();
}
```

When stock updates:
- `updatedAt` gets set to `DateTime.now()`
- Product moves to top of list
- Home screen shows top 3 as "Recent Items"

### 7. Product Update Mechanism

**Every change updates timestamp:**
```dart
await db.update('products', {
  'currentQuantity': newQuantity,
  'updatedAt': DateTime.now().toIso8601String(),  // This!
});
```

**Why this works:**
- Stock change → `updatedAt` updates
- Query sorts by `updatedAt DESC`
- Most recently changed products appear first
- Simple and automatic

---

## Database

**Location:** `.dart_tool/sqflite_common_ffi/databases/stockmate.db`

**Tables:**
- `products` - all product data
- `stock_movements` - change history

**Linux Fix:**
Had to manually load SQLite library:
```dart
DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so');
```

---

## Products (Current Data)

Seeded 5 chip products:
- P001: Lays Classic (15 in stock)
- P002: Pringles (3 in stock - LOW)
- P003: Doritos (25 in stock)
- P004: Cheetos (0 in stock - OUT)
- P005: Ruffles (8 in stock - LOW)

---

## What Works

✅ Splash screen → Home screen navigation  
✅ Display products from database  
✅ Real-time stock updates  
✅ Low stock alerts  
✅ Statistics calculation  
✅ Desktop window locked to 400x800  

---

## What's Missing

- Product list screen (bottom nav ready, screen not built)
- Add product form
- Product details screen
- Analytics/reports
- Image picker
- Barcode scanner

---

## Key Decisions

**Soft Delete:** Products set `isDeleted = 1` instead of actual deletion  
**History Tracking:** Every stock change logged for audit trail  
**Singleton Database:** One DB instance shared across app  

---

That's it. Foundation is solid, ready to add more screens later.

— Reaksa

