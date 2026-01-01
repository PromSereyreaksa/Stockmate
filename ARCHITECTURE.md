# StockMate - Offline Stock Management App

A Flutter mobile application for small home-based sellers in Cambodia to manage their inventory offline.

## Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── data/               # Data layer
│   └── mock_data_source.dart
├── models/             # Domain models
│   ├── product.dart
│   └── stock_summary.dart
├── ui/                 # Presentation layer
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   └── widgets/
│       ├── summary_card.dart
│       ├── stock_alert_card.dart
│       └── recent_item_card.dart
└── main.dart
```

### Layers

**Data Layer (`lib/data/`)**
- `MockDataSource`: Provides mock data for the MVP
- In production, this would be replaced with a database repository using SQLite

**Models Layer (`lib/models/`)**
- `Product`: Represents a product with stock information
- `StockSummary`: Contains summary statistics for the dashboard

**UI Layer (`lib/ui/`)**
- **No business logic in UI components**
- Screens receive data via models only
- Widgets are purely presentational

## Features Implemented

### Splash Screen
- Blue branded screen with app icon
- 2-second delay before navigating to home

### Home Screen
- **Header Card**: App branding with icon
- **Summary Cards**: 
  - Total Items count
  - Low Stock alerts count
- **Stock Alerts Section**: 
  - Shows products with low stock (≤5 items) or out of stock
  - Color-coded borders (yellow for low stock, red for out of stock)
- **Recent Items Section**:
  - Displays recent products
  - Quantity controls (+/- buttons) for quick stock updates
- **Bottom Navigation**: Home, Items, Add, Reports (placeholder)

## Design System

### Colors
- Primary: Blue (`Colors.blue`)
- Background: Light gray (`#F5F5F5`)
- Cards: White with subtle shadows
- Alerts: Orange (low stock), Red (out of stock)

### Typography
- Header: 20px bold
- Section titles: 18px bold
- Body text: 16px regular
- Labels: 14px regular

### Components
- Rounded cards with 12-16px border radius
- Subtle shadows for depth
- Material Icons throughout
- Consistent 16px horizontal padding

## Mock Data

Products are stored in `assets/products/`:

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# For Linux desktop
flutter run -d linux

# For Android
flutter run -d android
```

## Next Steps

- Implement SQLite database with `sqflite`
- Add Items screen with full product list
- Add product entry form
- Add Reports screen with analytics
- Implement local persistence
- Add barcode scanning for product lookup
- Add export functionality for reports
