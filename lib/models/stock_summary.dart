class StockSummary {
  final int totalItems;
  final int lowStockCount;

  StockSummary({
    required this.totalItems,
    required this.lowStockCount,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      totalItems: json['totalItems'] as int,
      lowStockCount: json['lowStockCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'lowStockCount': lowStockCount,
    };
  }
}
