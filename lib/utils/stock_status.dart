import 'package:flutter/material.dart';
import '../models/product.dart';

// file use for stock status and color acrross multiple widgets/screens

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  /// Get the display color for this stock status
  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return Colors.green;
      case StockStatus.lowStock:
        return Colors.orange;
      case StockStatus.outOfStock:
        return Colors.red;
    }
  }

  /// Get the display text for this stock status
  String get displayText {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  /// Determine the stock status from a product
  static StockStatus fromProduct(Product product) {
    if (product.isOutOfStock) {
      return StockStatus.outOfStock;
    } else if (product.isLowStock) {
      return StockStatus.lowStock;
    } else {
      return StockStatus.inStock;
    }
  }
}
