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

class StockMovementData {
  final DateTime date;
  final int stockIn;
  final int stockOut;

  StockMovementData({
    required this.date,
    required this.stockIn,
    required this.stockOut,
  });

  Map<String, Object?> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'stock_in': stockIn,
      'stock_out': stockOut,
    };
  }

  static StockMovementData fromDb(Map<String, Object?> row) {
    return StockMovementData(
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      stockIn: row['stock_in'] as int,
      stockOut: row['stock_out'] as int,
    );
  }
}

class StockMovementSummary {
  final int totalIn;
  final int totalOut;
  final List<StockMovementData> dailyData;

  StockMovementSummary({
    required this.totalIn,
    required this.totalOut,
    required this.dailyData,
  });

  factory StockMovementSummary.fromDailyData(
      List<StockMovementData> data) {
    final totalIn = data.fold(0, (sum, e) => sum + e.stockIn);
    final totalOut = data.fold(0, (sum, e) => sum + e.stockOut);

    return StockMovementSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      dailyData: data,
    );
  }
}

