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

