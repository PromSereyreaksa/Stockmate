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
