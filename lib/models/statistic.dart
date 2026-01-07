import 'product.dart';

class Statistics {
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValue;
  final double estimatedProfit;

  Statistics({
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalValue,
    required this.estimatedProfit,
  });

  /// Creates Statistics from a list of Product objects
  /// Makes the dependency on Product data explicit
  factory Statistics.fromProducts(List<Product> products) {
    int totalItems = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalValue = 0.0;
    double estimatedProfit = 0.0;

    for (var product in products) {
      // Only count non-deleted products
      if (product.isDeleted) continue;
      
      totalItems++;
      
      if (product.isLowStock) {
        lowStockCount++;
      }
      
      if (product.isOutOfStock) {
        outOfStockCount++;
      }
      
      totalValue += product.currentQuantity * product.costPrice;
      estimatedProfit += product.currentQuantity * product.profitMargin;
    }

    return Statistics(
      totalItems: totalItems,
      lowStockCount: lowStockCount,
      outOfStockCount: outOfStockCount,
      totalValue: totalValue,
      estimatedProfit: estimatedProfit,
    );
  }

  Map<String, Object?> toMap(){
    return{
      'total_items': totalItems,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'total_value': totalValue,
      'estimated_profit': estimatedProfit,
    };
  }

  static Statistics fromDb(Map<String, Object?> row) {
    return Statistics(
      totalItems: row['total_items'] as int,
      lowStockCount: row['low_stock_count'] as int,
      outOfStockCount: row['out_of_stock_count'] as int,
      totalValue: (row['total_value'] as num).toDouble(),
      estimatedProfit: (row['estimated_profit'] as num).toDouble(),
    );
  }
}

