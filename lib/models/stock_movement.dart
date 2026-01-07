class StockMovement {
  final int? id;
  final String productId;
  final int previousQty;
  final int newQty;
  final String changeType;
  final String? reason;
  final DateTime timestamp;

  StockMovement({
    this.id,
    required this.productId,
    required this.previousQty,
    required this.newQty,
    required this.changeType,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'previousQty': previousQty,
      'newQty': newQty,
      'changeType': changeType,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static StockMovement fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      productId: map['productId'] as String,
      previousQty: map['previousQty'] as int,
      newQty: map['newQty'] as int,
      changeType: map['changeType'] as String,
      reason: map['reason'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
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

  // Creates a StockMovementSummary from a list of StockMovement records
  // Groups movements by date and aggregates stock in/out values
  factory StockMovementSummary.fromMovements(
    List<StockMovement> movements,
    DateTime startDate,
    int days,
  ) {
    final endDate = startDate.add(Duration(days: days));
    
    // Initialize all dates in the range with normalized dates
    final Map<DateTime, StockMovementData> dailyMap = {};
    for (int i = 0; i < days; i++) {
      final date = _normalizeDate(startDate.add(Duration(days: i)));
      dailyMap[date] = StockMovementData(date: date, stockIn: 0, stockOut: 0);
    }

    // Aggregate movements by normalized date
    for (var movement in movements) {
      // Skip if outside range
      if (movement.timestamp.isBefore(startDate) || 
          movement.timestamp.isAfter(endDate)) {
        continue;
      }
      
      final normalizedDate = _normalizeDate(movement.timestamp);
      final current = dailyMap[normalizedDate];
      if (current == null) continue;
      
      final change = movement.newQty - movement.previousQty;
      
      // Aggregate based on change direction, not changeType
      if (change > 0) {
        dailyMap[normalizedDate] = StockMovementData(
          date: normalizedDate,
          stockIn: current.stockIn + change,
          stockOut: current.stockOut,
        );
      } else if (change < 0) {
        dailyMap[normalizedDate] = StockMovementData(
          date: normalizedDate,
          stockIn: current.stockIn,
          stockOut: current.stockOut + change.abs(),
        );
      }
    }

   
    final dailyData = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return StockMovementSummary.fromDailyData(dailyData);
  }

  
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
