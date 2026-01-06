import 'package:flutter/material.dart';
import '../models/product.dart';

// file use for stock status and color acrross multiple widgets/screens

enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
  expired,
  nearlyExpired;

  // Get the display color for this stock status
  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return Colors.green;
      case StockStatus.lowStock:
      case StockStatus.nearlyExpired:
        return Colors.orange;
      case StockStatus.outOfStock:
      case StockStatus.expired:
        return Colors.red;
    }
  }

  // Get the display text for this stock status
  String get displayText {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.nearlyExpired:
        return 'Nearly Expired';
      case StockStatus.expired:
        return 'Expired';
    }
  }

  /// Determine the stock status from a product
  static StockStatus fromProduct(Product product) {
    if (product.isOutOfStock) {
      return StockStatus.outOfStock;
    } else if (product.isLowStock) {
      return StockStatus.lowStock;
    } else if (product.isNearlyExpired) {
      return StockStatus.nearlyExpired;
    } else if (product.isExpired) {
      return StockStatus.expired;
    } else {
      return StockStatus.inStock;
    }
  }
}
